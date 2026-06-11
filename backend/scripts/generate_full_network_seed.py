from collections import defaultdict
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
GO_FILE = ROOT / "backend" / "go" / "services" / "metro_network_data.go"
OUT_FILE = ROOT / "backend" / "migrations" / "004_full_shanghai_metro_network.sql"


def sql(value: str) -> str:
    return "'" + str(value).replace("\\", "\\\\").replace("'", "''") + "'"


def section_between(text: str, start_marker: str, end_marker: str) -> str:
    start = text.index(start_marker)
    end = text.index(end_marker, start)
    return text[start:end]


def generic_exits(name: str):
    return [
        ("1号口", f"{name}站周边主干道", "优先跟随站内1号口导向，适合前往主干道与公交换乘点", 1),
        ("2号口", f"{name}站商业与社区方向", "适合前往周边商业、社区和步行目的地", 0),
        ("3号口", f"{name}站道路对侧", "适合前往道路对侧，减少地面绕行", 0),
        ("4号口", f"{name}站公共交通接驳区", "适合换乘公交、出租或网约车", 1),
    ]


def main() -> None:
    text = GO_FILE.read_text(encoding="utf-8")
    line_names = dict(
        re.findall(
            r'"([^"]+)"\s*:\s*"([^"]+)"',
            section_between(text, "var metroNetworkLineNames", "var metroNetworkLineColors"),
        )
    )
    line_colors = dict(
        re.findall(
            r'"([^"]+)"\s*:\s*"([^"]+)"',
            section_between(text, "var metroNetworkLineColors", "var metroNetworkLines"),
        )
    )
    block = section_between(
        text,
        "var metroNetworkLines = map[string][]metroNetworkStation{",
        "var metroNetworkStationIDToName",
    )

    lines = {}
    for match in re.finditer(r'\n\s*"([^"]+)"\s*:\s*\{(.*?)\n\s*\},', block, re.S):
        line_id = match.group(1)
        body = match.group(2)
        stations = []
        for item in re.finditer(r'\{ID:\s*"([^"]+)",\s*Name:\s*"([^"]+)",\s*Order:\s*(\d+)\}', body):
            stations.append({"id": item.group(1), "name": item.group(2), "order": int(item.group(3))})
        if stations:
            lines[line_id] = stations

    ordered_line_ids = [str(i) for i in range(1, 19)]
    name_to_lines = defaultdict(list)
    name_to_ids = defaultdict(list)
    for line_id in ordered_line_ids:
        for station in lines.get(line_id, []):
            if line_id not in name_to_lines[station["name"]]:
                name_to_lines[station["name"]].append(line_id)
            if station["id"] not in name_to_ids[station["name"]]:
                name_to_ids[station["name"]].append(station["id"])

    canonical = {}
    for line_id in ordered_line_ids:
        for station in lines.get(line_id, []):
            canonical.setdefault(station["name"], station["id"])

    special_exits = {
        "同济大学": [
            ("1号口", "同济大学四平路校区、彰武路", "靠近校园方向，适合前往教学楼和校内主干道", 1),
            ("2号口", "四平路、赤峰路", "适合前往四平路沿线和公交换乘点", 0),
            ("3号口", "彰武路、同济联合广场", "适合前往周边商业与办公区域", 0),
            ("4号口", "四平路东侧", "适合前往道路东侧和出租车上客点", 0),
        ],
        "上海火车站": [
            ("1号口", "上海火车站南广场", "跟随南广场与铁路出发导向，适合进站乘火车", 1),
            ("2号口", "秣陵路、铁路售票处", "适合前往售票处和南广场西侧", 0),
            ("3号口", "天目西路", "适合前往天目西路沿线", 0),
            ("4号口", "北广场换乘通道", "适合换乘公交、出租和长途客运方向", 1),
        ],
        "虹桥火车站": [
            ("A口", "虹桥火车站到达层", "跟随铁路到达和出发导向，适合换乘高铁", 1),
            ("B口", "虹桥天地", "适合前往商业区和办公区", 0),
            ("C口", "虹桥枢纽东交通中心", "适合换乘公交和出租", 1),
            ("D口", "虹桥机场2号航站楼方向", "适合前往机场和航站楼连廊", 1),
        ],
        "浦东国际机场": [
            ("1号口", "浦东机场1号航站楼", "跟随T1导向，适合前往1号航站楼", 1),
            ("2号口", "浦东机场2号航站楼", "跟随T2导向，适合前往2号航站楼", 1),
            ("3号口", "磁浮与交通中心", "适合换乘磁浮、公交和出租", 1),
            ("4号口", "停车楼与接驳区", "适合前往停车楼和网约车接驳", 0),
        ],
        "五角场": [
            ("1号口", "五角场商圈、合生汇", "适合前往合生汇和商圈核心区", 0),
            ("2号口", "淞沪路、万达广场", "适合前往万达广场和淞沪路沿线", 0),
            ("3号口", "政通路", "适合前往政通路和办公区", 0),
            ("4号口", "翔殷路", "适合前往翔殷路和公交换乘点", 0),
        ],
    }

    statements = ["USE smart_travel;", "SET FOREIGN_KEY_CHECKS = 0;"]
    for table in [
        "line_station_transfer_lines",
        "transfer_rule_transfer_lines",
        "transfer_rule_tags",
        "transfer_rules",
        "line_stations",
        "line_directions",
        "station_exits",
        "station_facilities",
        "static_resources",
        "metro_lines",
        "stations",
    ]:
        statements.append(f"DELETE FROM {table};")
    statements.append("SET FOREIGN_KEY_CHECKS = 1;")

    for line_id in ordered_line_ids:
        if line_id not in lines:
            continue
        name = line_names.get(line_id, f"{line_id}号线")
        color = line_colors.get(line_id, "#6B7280")
        desc = f"上海地铁{name}，站点数据来自项目内置全网线路数据。"
        statements.append(
            "INSERT INTO metro_lines (line_id, line_name, city, color_name, color_hex, description) VALUES "
            f"({sql(line_id)}, {sql(name)}, '上海', {sql(name)}, {sql(color)}, {sql(desc)}) "
            "ON DUPLICATE KEY UPDATE line_name=VALUES(line_name), color_hex=VALUES(color_hex), description=VALUES(description);"
        )

    for name in sorted(canonical.keys(), key=lambda item: canonical[item]):
        station_id = canonical[name]
        line_list = name_to_lines[name]
        station_type = "换乘站" if len(line_list) > 1 else "地铁站"
        alias = ",".join(name_to_ids[name])
        desc = f"{name}站，服务线路：" + "、".join(f"{line_id}号线" for line_id in line_list)
        statements.append(
            "INSERT INTO stations (station_id, station_name, station_alias, city, district, station_type, description) VALUES "
            f"({sql(station_id)}, {sql(name)}, {sql(alias)}, '上海', '', {sql(station_type)}, {sql(desc)}) "
            "ON DUPLICATE KEY UPDATE station_name=VALUES(station_name), station_alias=VALUES(station_alias), "
            "station_type=VALUES(station_type), description=VALUES(description);"
        )

    for line_id in ordered_line_ids:
        stations = lines.get(line_id, [])
        if not stations:
            continue
        for direction in (stations[0]["name"], stations[-1]["name"]):
            statements.append(
                f"INSERT INTO line_directions (line_id, direction) VALUES ({sql(line_id)}, {sql(direction)}) "
                "ON DUPLICATE KEY UPDATE direction=VALUES(direction);"
            )
        for station in stations:
            station_id = canonical[station["name"]]
            is_transfer = 1 if len(name_to_lines[station["name"]]) > 1 else 0
            line_name = line_names.get(line_id, f"{line_id}号线")
            if is_transfer:
                tip = f"{line_name} {station['name']}站，按站内导向选择站台；换乘站请留意换乘通道。"
            else:
                tip = f"{line_name} {station['name']}站，按站台导向乘车。"
            statements.append(
                "INSERT INTO line_stations (line_id, station_id, direction, station_order, is_transfer, platform_tip) VALUES "
                f"({sql(line_id)}, {sql(station_id)}, '双向', {station['order']}, {is_transfer}, {sql(tip)});"
            )

    statements.append(
        "INSERT INTO line_station_transfer_lines (line_station_id, transfer_line_id) "
        "SELECT ls.id, other.line_id FROM line_stations ls "
        "JOIN line_stations other ON other.station_id = ls.station_id AND other.line_id <> ls.line_id "
        "ON DUPLICATE KEY UPDATE transfer_line_id = VALUES(transfer_line_id);"
    )

    for name, station_id in canonical.items():
        for exit_name, nearby, tip, accessible in special_exits.get(name, generic_exits(name)):
            suffix = exit_name.replace("号口", "").replace("口", "").replace(" ", "_")
            exit_id = f"{station_id}_{suffix}"
            statements.append(
                "INSERT INTO station_exits (exit_id, station_id, exit_name, nearby_place, guide_tip, is_accessible) VALUES "
                f"({sql(exit_id)}, {sql(station_id)}, {sql(exit_name)}, {sql(nearby)}, {sql(tip)}, {accessible}) "
                "ON DUPLICATE KEY UPDATE nearby_place=VALUES(nearby_place), guide_tip=VALUES(guide_tip), is_accessible=VALUES(is_accessible);"
            )
        is_hub = len(name_to_lines[name]) > 1
        elevator_count = 2 if is_hub else 1
        escalator_count = 4 if is_hub else 2
        note = "换乘站，建议预留更多换乘和步行时间。" if is_hub else "基础设施信息，具体位置以站内导向为准。"
        statements.append(
            "INSERT INTO station_facilities (station_id, has_elevator, has_escalator, has_wheelchair_ramp, has_wide_gate, "
            "has_accessible_restroom, has_blind_path, elevator_count, escalator_count, facility_note) VALUES "
            f"({sql(station_id)}, 1, 1, 1, 1, 1, 1, {elevator_count}, {escalator_count}, {sql(note)}) "
            "ON DUPLICATE KEY UPDATE elevator_count=VALUES(elevator_count), escalator_count=VALUES(escalator_count), "
            "facility_note=VALUES(facility_note);"
        )

    rule_specs = [
        ("tongji_to_shanghai_railway_10_1", "同济大学", "10", "陕西南路", "虹桥火车站", 8, 18, "下车后按1号线换乘导向，优先选择靠近换乘通道车厢。", ["少步行", "换乘"]),
        ("tongji_to_wujiaochang_10", "同济大学", "10", "五角场", "基隆路", 2, 5, "短途直达，留意列车方向。", ["直达", "短途"]),
        ("tongji_to_pudong_airport_10_2", "同济大学", "10", "南京东路", "虹桥火车站", 6, 16, "在南京东路换乘2号线后前往浦东国际机场方向。", ["机场", "换乘"]),
        ("hongqiao_to_pudong_airport_2", "虹桥火车站", "2", "浦东国际机场", "浦东国际机场", 28, 70, "2号线长距离直达，建议预留机场安检和步行时间。", ["机场", "直达"]),
        ("shanghai_railway_to_peoples_square_1", "上海火车站", "1", "人民广场", "莘庄", 3, 8, "到人民广场可换乘2号线、8号线。", ["换乘", "市中心"]),
    ]
    for rule_id, origin_name, line_id, target_name, direction, stops, minutes, tip, tags in rule_specs:
        if origin_name not in canonical or target_name not in canonical or line_id not in lines:
            continue
        origin = canonical[origin_name]
        target = canonical[target_name]
        statements.append(
            "INSERT INTO transfer_rules (rule_id, origin_station_id, line_id, target_station_id, direction, stops_count, "
            "estimated_minutes, carriage_suggestion, transfer_tip, data_level) VALUES "
            f"({sql(rule_id)}, {sql(origin)}, {sql(line_id)}, {sql(target)}, {sql(direction)}, {stops}, {minutes}, "
            f"'中部车厢', {sql(tip)}, 'manual') "
            "ON DUPLICATE KEY UPDATE estimated_minutes=VALUES(estimated_minutes), transfer_tip=VALUES(transfer_tip), data_level=VALUES(data_level);"
        )
        for tag in tags:
            statements.append(
                f"INSERT INTO transfer_rule_tags (transfer_rule_id, tag) SELECT id, {sql(tag)} FROM transfer_rules WHERE rule_id = {sql(rule_id)} "
                "ON DUPLICATE KEY UPDATE tag = VALUES(tag);"
            )
        for transfer_line in name_to_lines[target_name]:
            if transfer_line != line_id:
                statements.append(
                    f"INSERT INTO transfer_rule_transfer_lines (transfer_rule_id, transfer_line_id) SELECT id, {sql(transfer_line)} FROM transfer_rules WHERE rule_id = {sql(rule_id)} "
                    "ON DUPLICATE KEY UPDATE transfer_line_id = VALUES(transfer_line_id);"
                )

    resources = [
        ("photo", "station-photo-fallback", "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=1200&q=80", "站点实景照片兜底资源"),
        ("diagram", "full-shanghai-metro-network", "backend/go/services/metro_network_data.go", "上海地铁1-18号线全网演示数据源"),
        ("icon", "accessibility", "app/assets/icons/accessibility.png", "无障碍设施图标"),
    ]
    for resource_type, resource_name, resource_path, description in resources:
        statements.append(
            "INSERT INTO static_resources (resource_type, resource_name, resource_path, description) VALUES "
            f"({sql(resource_type)}, {sql(resource_name)}, {sql(resource_path)}, {sql(description)}) "
            "ON DUPLICATE KEY UPDATE resource_path=VALUES(resource_path), description=VALUES(description);"
        )

    statements.append(
        "SELECT 'full_shanghai_metro_network_loaded' AS status, "
        "(SELECT COUNT(*) FROM metro_lines) AS metro_lines, "
        "(SELECT COUNT(*) FROM stations) AS stations, "
        "(SELECT COUNT(*) FROM line_stations) AS line_stations, "
        "(SELECT COUNT(*) FROM station_exits) AS station_exits;"
    )
    header = (
        "-- Auto-generated from backend/go/services/metro_network_data.go.\n"
        "-- Keeps the MySQL seed aligned with the backend in-memory Shanghai metro network.\n\n"
    )
    OUT_FILE.write_text(header + "\n".join(statements) + "\n", encoding="utf-8")
    print(
        f"Wrote {OUT_FILE}\n"
        f"lines={len(lines)} stations={len(canonical)} "
        f"line_station_rows={sum(len(items) for items in lines.values())}"
    )


if __name__ == "__main__":
    main()
