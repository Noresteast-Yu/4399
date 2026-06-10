package services

import (
	"strings"

	"smart-travel-backend/models"
)

type metroNetworkStation struct {
	ID    string
	Name  string
	Order int
}

type MetroNetworkStationSummary struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Order int    `json:"order"`
}

type MetroNetworkLineSummary struct {
	ID            string                       `json:"id"`
	Name          string                       `json:"name"`
	City          string                       `json:"city"`
	Color         string                       `json:"color"`
	Directions    []string                     `json:"directions"`
	FirstTrain    string                       `json:"firstTrain"`
	LastTrain     string                       `json:"lastTrain"`
	Interval      string                       `json:"interval"`
	CrowdingLevel string                       `json:"crowdingLevel"`
	StationCount  int                          `json:"stationCount"`
	Stations      []MetroNetworkStationSummary `json:"stations"`
}

var metroNetworkLineNames = map[string]string{
	"1":  "1号线",
	"2":  "2号线",
	"3":  "3号线",
	"4":  "4号线（环线）",
	"5":  "5号线",
	"6":  "6号线",
	"7":  "7号线",
	"8":  "8号线",
	"9":  "9号线",
	"10": "10号线",
	"11": "11号线",
	"12": "12号线",
	"13": "13号线",
	"14": "14号线",
	"15": "15号线",
	"16": "16号线",
	"17": "17号线",
	"18": "18号线",
}
var metroNetworkLineColors = map[string]string{
	"1":  "#E4002B",
	"2":  "#8CC63F",
	"3":  "#FFD100",
	"4":  "#5F259F",
	"5":  "#944D9B",
	"6":  "#D40068",
	"7":  "#ED6D00",
	"8":  "#009BDE",
	"9":  "#71BF45",
	"10": "#C5A3FF",
	"11": "#7A3E2F",
	"12": "#007A3D",
	"13": "#F3A1C8",
	"14": "#B2A72C",
	"15": "#BDA678",
	"16": "#00B5AD",
	"17": "#B08A00",
	"18": "#C8A45D",
}
var metroNetworkLines = map[string][]metroNetworkStation{
	"1": {
		{ID: "fujin_road", Name: "富锦路", Order: 1},
		{ID: "youyi_west", Name: "友谊西路", Order: 2},
		{ID: "baoan_highway", Name: "宝安公路", Order: 3},
		{ID: "gongfu_xincun", Name: "共富新村", Order: 4},
		{ID: "hulan_road", Name: "呼兰路", Order: 5},
		{ID: "tonghe_xincun", Name: "通河新村", Order: 6},
		{ID: "gongkang_road", Name: "共康路", Order: 7},
		{ID: "pengpu_xincun", Name: "彭浦新村", Order: 8},
		{ID: "wenxi_road", Name: "汶水路", Order: 9},
		{ID: "shanghai_circus", Name: "上海马戏城", Order: 10},
		{ID: "yanchang_road", Name: "延长路", Order: 11},
		{ID: "zhongshan_north", Name: "中山北路", Order: 12},
		{ID: "shanghai_railway_1", Name: "上海火车站", Order: 13},
		{ID: "hanzhong_road", Name: "汉中路", Order: 14},
		{ID: "xinzha_road", Name: "新闸路", Order: 15},
		{ID: "peoples_square", Name: "人民广场", Order: 16},
		{ID: "huangpi_south_1", Name: "黄陂南路", Order: 17},
		{ID: "shaanxi_south_1", Name: "陕西南路", Order: 18},
		{ID: "changshu_road_1", Name: "常熟路", Order: 19},
		{ID: "hengshan_road", Name: "衡山路", Order: 20},
		{ID: "xujiahui", Name: "徐家汇", Order: 21},
		{ID: "shanghai_indoor", Name: "上海体育馆", Order: 22},
		{ID: "caobao_road_1", Name: "漕宝路", Order: 23},
		{ID: "shanghai_south_1", Name: "上海南站", Order: 24},
		{ID: "jinjiang_park", Name: "锦江乐园", Order: 25},
		{ID: "lianhua_road", Name: "莲花路", Order: 26},
		{ID: "waihuanlu", Name: "外环路", Order: 27},
		{ID: "xinzhuang", Name: "莘庄", Order: 28},
	},
	"2": {
		{ID: "east_xujing", Name: "徐泾东", Order: 1},
		{ID: "hongqiao_railway_2", Name: "虹桥火车站", Order: 2},
		{ID: "hongqiao_t2_2", Name: "虹桥2号航站楼", Order: 3},
		{ID: "songhong_road", Name: "淞虹路", Order: 4},
		{ID: "beixinjing", Name: "北新泾", Order: 5},
		{ID: "weining_road", Name: "威宁路", Order: 6},
		{ID: "loushanguan_2", Name: "娄山关路", Order: 7},
		{ID: "zhongshan_park_2", Name: "中山公园", Order: 8},
		{ID: "jiangsu_road_2", Name: "江苏路", Order: 9},
		{ID: "jingan_temple_2", Name: "静安寺", Order: 10},
		{ID: "nanjing_west_2", Name: "南京西路", Order: 11},
		{ID: "peoples_square_2", Name: "人民广场", Order: 12},
		{ID: "nanjing_east_2", Name: "南京东路", Order: 13},
		{ID: "lujiazui_2", Name: "陆家嘴", Order: 14},
		{ID: "dongchang_road_2", Name: "东昌路", Order: 15},
		{ID: "century_avenue_2", Name: "世纪大道", Order: 16},
		{ID: "shanghai_sci_2", Name: "上海科技馆", Order: 17},
		{ID: "century_park", Name: "世纪公园", Order: 18},
		{ID: "longyang_road_2", Name: "龙阳路", Order: 19},
		{ID: "zhangjiang_high", Name: "张江高科", Order: 20},
		{ID: "jinke_road_2", Name: "金科路", Order: 21},
		{ID: "guanglan_road_2", Name: "广兰路", Order: 22},
		{ID: "tangzhen", Name: "唐镇", Order: 23},
		{ID: "chuansha_2", Name: "川沙", Order: 24},
		{ID: "pudong_airport_2", Name: "浦东国际机场", Order: 25},
	},
	"3": {
		{ID: "north_jiangyang", Name: "江杨北路", Order: 1},
		{ID: "tieli_road", Name: "铁力路", Order: 2},
		{ID: "youyi_road_3", Name: "友谊路", Order: 3},
		{ID: "baoyang_road", Name: "宝杨路", Order: 4},
		{ID: "shuichan_road", Name: "水产路", Order: 5},
		{ID: "songbin_road", Name: "淞滨路", Order: 6},
		{ID: "zhanghuabang", Name: "张华浜", Order: 7},
		{ID: "songfa_road", Name: "淞发路", Order: 8},
		{ID: "changjiang_south", Name: "长江南路", Order: 9},
		{ID: "west_yingao", Name: "殷高西路", Order: 10},
		{ID: "jiangwan_town_3", Name: "江湾镇", Order: 11},
		{ID: "dabaishu_3", Name: "大柏树", Order: 12},
		{ID: "chifeng_road_3", Name: "赤峰路", Order: 13},
		{ID: "hongkou_football_3", Name: "虹口足球场", Order: 14},
		{ID: "dongbaoxing_road", Name: "东宝兴路", Order: 15},
		{ID: "baoshan_road_3", Name: "宝山路", Order: 16},
		{ID: "shanghai_railway_3", Name: "上海火车站", Order: 17},
		{ID: "zhongtan_road_3", Name: "中潭路", Order: 18},
		{ID: "zhenping_road_3", Name: "镇坪路", Order: 19},
		{ID: "caoyang_road_3", Name: "曹杨路", Order: 20},
		{ID: "jinshajiang_road_3", Name: "金沙江路", Order: 21},
		{ID: "zhongshan_park_3", Name: "中山公园", Order: 22},
		{ID: "yanan_west_road", Name: "延安西路", Order: 23},
		{ID: "hongqiao_road_3", Name: "虹桥路", Order: 24},
		{ID: "yishan_road_3", Name: "宜山路", Order: 25},
		{ID: "caoxi_road", Name: "漕溪路", Order: 26},
		{ID: "longcao_road_3", Name: "龙漕路", Order: 27},
		{ID: "shilong_road", Name: "石龙路", Order: 28},
		{ID: "shanghai_south_3", Name: "上海南站", Order: 29},
	},
	"4": {
		{ID: "yishan_road_4", Name: "宜山路", Order: 1},
		{ID: "hongqiao_road_4", Name: "虹桥路", Order: 2},
		{ID: "yanan_west_4", Name: "延安西路", Order: 3},
		{ID: "zhongshan_park_4", Name: "中山公园", Order: 4},
		{ID: "jinshajiang_road_4", Name: "金沙江路", Order: 5},
		{ID: "caoyang_road_4", Name: "曹杨路", Order: 6},
		{ID: "zhenping_road_4", Name: "镇坪路", Order: 7},
		{ID: "zhongtan_road_4", Name: "中潭路", Order: 8},
		{ID: "shanghai_railway_4", Name: "上海火车站", Order: 9},
		{ID: "baoshan_road_4", Name: "宝山路", Order: 10},
		{ID: "hailun_road_4", Name: "海伦路", Order: 11},
		{ID: "linping_road", Name: "临平路", Order: 12},
		{ID: "dalian_road_4", Name: "大连路", Order: 13},
		{ID: "yangshupu_road", Name: "杨树浦路", Order: 14},
		{ID: "pudong_avenue_4", Name: "浦东大道", Order: 15},
		{ID: "century_avenue_4", Name: "世纪大道", Order: 16},
		{ID: "pudian_road_4", Name: "浦电路", Order: 17},
		{ID: "lancun_road_4", Name: "蓝村路", Order: 18},
		{ID: "tangqiao", Name: "塘桥", Order: 19},
		{ID: "nanpu_bridge", Name: "南浦大桥", Order: 20},
		{ID: "xizang_south_4", Name: "西藏南路", Order: 21},
		{ID: "luban_road", Name: "鲁班路", Order: 22},
		{ID: "damuqiao_road_4", Name: "大木桥路", Order: 23},
		{ID: "dongan_road_4", Name: "东安路", Order: 24},
		{ID: "shanghai_stadium_4", Name: "上海体育场", Order: 25},
		{ID: "shanghai_indoor_4", Name: "上海体育馆", Order: 26},
	},
	"5": {
		{ID: "xinzhuang_5", Name: "莘庄", Order: 1},
		{ID: "chunshen_road", Name: "春申路", Order: 2},
		{ID: "yindu_road", Name: "银都路", Order: 3},
		{ID: "zhuanqiao", Name: "颛桥", Order: 4},
		{ID: "beiqiao", Name: "北桥", Order: 5},
		{ID: "jianchuan_road", Name: "剑川路", Order: 6},
		{ID: "dongchuan_road_5", Name: "东川路", Order: 7},
		{ID: "jinping_road", Name: "金平路", Order: 8},
		{ID: "huaning_road", Name: "华宁路", Order: 9},
		{ID: "wenjing_road", Name: "文井路", Order: 10},
		{ID: "minhang_dev", Name: "闵行开发区", Order: 11},
	},
	"6": {
		{ID: "gangcheng_road", Name: "港城路", Order: 1},
		{ID: "north_waigaoqiao", Name: "外高桥保税区北", Order: 2},
		{ID: "hangjin_road", Name: "航津路", Order: 3},
		{ID: "south_waigaoqiao", Name: "外高桥保税区南", Order: 4},
		{ID: "zhouhai_road", Name: "洲海路", Order: 5},
		{ID: "wuzhou_avenue", Name: "五洲大道", Order: 6},
		{ID: "dongjing_road", Name: "东靖路", Order: 7},
		{ID: "jufeng_road", Name: "巨峰路", Order: 8},
		{ID: "wulian_road", Name: "五莲路", Order: 9},
		{ID: "boxing_road", Name: "博兴路", Order: 10},
		{ID: "jinqiao_road_6", Name: "金桥路", Order: 11},
		{ID: "yunshan_road", Name: "云山路", Order: 12},
		{ID: "deping_road", Name: "德平路", Order: 13},
		{ID: "beiyangjing_road", Name: "北洋泾路", Order: 14},
		{ID: "minsheng_road", Name: "民生路", Order: 15},
		{ID: "yuanshen_stadium", Name: "源深体育中心", Order: 16},
		{ID: "century_avenue_6", Name: "世纪大道", Order: 17},
		{ID: "pudian_road_6", Name: "浦电路", Order: 18},
		{ID: "lancun_road_6", Name: "蓝村路", Order: 19},
		{ID: "shanghai_children", Name: "上海儿童医学中心", Order: 20},
		{ID: "linyi_xincun", Name: "临沂新村", Order: 21},
		{ID: "gaoke_west_6", Name: "高科西路", Order: 22},
		{ID: "dongming_road_6", Name: "东明路", Order: 23},
		{ID: "gaoqing_road", Name: "高青路", Order: 24},
		{ID: "west_huaxia", Name: "华夏西路", Order: 25},
		{ID: "shangnan_road_6", Name: "上南路", Order: 26},
		{ID: "lingyan_south", Name: "灵岩南路", Order: 27},
		{ID: "oriental_sports_6", Name: "东方体育中心", Order: 28},
	},
	"7": {
		{ID: "meilan_lake", Name: "美兰湖", Order: 1},
		{ID: "luonan_xincun", Name: "罗南新村", Order: 2},
		{ID: "panguang_road", Name: "潘广路", Order: 3},
		{ID: "liuhang", Name: "刘行", Order: 4},
		{ID: "gucun_park_7", Name: "顾村公园", Order: 5},
		{ID: "qihua_road", Name: "祁华路", Order: 6},
		{ID: "shanghai_univ", Name: "上海大学", Order: 7},
		{ID: "nanchen_road", Name: "南陈路", Order: 8},
		{ID: "shangda_road", Name: "上大路", Order: 9},
		{ID: "changzhong_road", Name: "场中路", Order: 10},
		{ID: "dachang_town", Name: "大场镇", Order: 11},
		{ID: "xingzhi_road", Name: "行知路", Order: 12},
		{ID: "dahuasan_road", Name: "大华三路", Order: 13},
		{ID: "xincun_road_7", Name: "新村路", Order: 14},
		{ID: "langui_road", Name: "岚皋路", Order: 15},
		{ID: "zhenping_road_7", Name: "镇坪路", Order: 16},
		{ID: "changshou_road_7", Name: "长寿路", Order: 17},
		{ID: "changping_road", Name: "昌平路", Order: 18},
		{ID: "jingan_temple_7", Name: "静安寺", Order: 19},
		{ID: "changshu_road_7", Name: "常熟路", Order: 20},
		{ID: "zhaojiabang_road_7", Name: "肇嘉浜路", Order: 21},
		{ID: "dongan_road_7", Name: "东安路", Order: 22},
		{ID: "longhua_mid_7", Name: "龙华中路", Order: 23},
		{ID: "houtan", Name: "后滩", Order: 24},
		{ID: "changqing_road_7", Name: "长清路", Order: 25},
		{ID: "yaohua_road_7", Name: "耀华路", Order: 26},
		{ID: "yuntai_road", Name: "云台路", Order: 27},
		{ID: "gaoke_west_7", Name: "高科西路", Order: 28},
		{ID: "yanggao_south_7", Name: "杨高南路", Order: 29},
		{ID: "jinxiu_road_7", Name: "锦绣路", Order: 30},
		{ID: "fanghua_road", Name: "芳华路", Order: 31},
		{ID: "longyang_road_7", Name: "龙阳路", Order: 32},
		{ID: "huamu_road", Name: "花木路", Order: 33},
	},
	"8": {
		{ID: "shiguang_road", Name: "市光路", Order: 1},
		{ID: "nenjiang_road", Name: "嫩江路", Order: 2},
		{ID: "xiangyin_road", Name: "翔殷路", Order: 3},
		{ID: "huangxing_park", Name: "黄兴公园", Order: 4},
		{ID: "yanji_mid_road", Name: "延吉中路", Order: 5},
		{ID: "huangxing_road", Name: "黄兴路", Order: 6},
		{ID: "jiangpu_road_8", Name: "江浦路", Order: 7},
		{ID: "anshan_xincun", Name: "鞍山新村", Order: 8},
		{ID: "siping_road_8", Name: "四平路", Order: 9},
		{ID: "quyang_road_8", Name: "曲阳路", Order: 10},
		{ID: "hongkou_football_8", Name: "虹口足球场", Order: 11},
		{ID: "xizang_north", Name: "西藏北路", Order: 12},
		{ID: "zhongxing_road", Name: "中兴路", Order: 13},
		{ID: "qufu_road_8", Name: "曲阜路", Order: 14},
		{ID: "peoples_square_8", Name: "人民广场", Order: 15},
		{ID: "dashijie_8", Name: "大世界", Order: 16},
		{ID: "laoximen_8", Name: "老西门", Order: 17},
		{ID: "lujiabang_road_8", Name: "陆家浜路", Order: 18},
		{ID: "xizang_south_8", Name: "西藏南路", Order: 19},
		{ID: "yaohua_road_8", Name: "耀华路", Order: 20},
		{ID: "chengshan_road", Name: "成山路", Order: 21},
		{ID: "yangsi_8", Name: "杨思", Order: 22},
		{ID: "oriental_sports_8", Name: "东方体育中心", Order: 23},
		{ID: "lingzhao_xincun", Name: "凌兆新村", Order: 24},
		{ID: "luheng_road", Name: "芦恒路", Order: 25},
		{ID: "pujiang_town_8", Name: "浦江镇", Order: 26},
		{ID: "jiangyue_road", Name: "江月路", Order: 27},
		{ID: "lianhang_road", Name: "联航路", Order: 28},
		{ID: "shendu_highway_8", Name: "沈杜公路", Order: 29},
	},
	"9": {
		{ID: "songjiang_south_9", Name: "松江南站", Order: 1},
		{ID: "zuibaichi_park", Name: "醉白池", Order: 2},
		{ID: "songjiang_sports", Name: "松江体育中心", Order: 3},
		{ID: "songjiang_xincheng", Name: "松江新城", Order: 4},
		{ID: "songjiang_univ", Name: "松江大学城", Order: 5},
		{ID: "dongjing_9", Name: "洞泾", Order: 6},
		{ID: "sheshan", Name: "佘山", Order: 7},
		{ID: "sijing", Name: "泗泾", Order: 8},
		{ID: "jiuting", Name: "九亭", Order: 9},
		{ID: "zhongchun_road", Name: "中春路", Order: 10},
		{ID: "qibao", Name: "七宝", Order: 11},
		{ID: "xingzhong_road", Name: "星中路", Order: 12},
		{ID: "hechuan_road", Name: "合川路", Order: 13},
		{ID: "caohejing_dev", Name: "漕河泾开发区", Order: 14},
		{ID: "guilin_road_9", Name: "桂林路", Order: 15},
		{ID: "yishan_road_9", Name: "宜山路", Order: 16},
		{ID: "xujiahui_9", Name: "徐家汇", Order: 17},
		{ID: "zhaojiabang_road_9", Name: "肇嘉浜路", Order: 18},
		{ID: "jiashan_road_9", Name: "嘉善路", Order: 19},
		{ID: "dapuqiao_9", Name: "打浦桥", Order: 20},
		{ID: "malu_road_9", Name: "马当路", Order: 21},
		{ID: "lujiabang_road_9", Name: "陆家浜路", Order: 22},
		{ID: "xiaonanmen", Name: "小南门", Order: 23},
		{ID: "shangcheng_road_9", Name: "商城路", Order: 24},
		{ID: "century_avenue_9", Name: "世纪大道", Order: 25},
		{ID: "middle_yanggao_9", Name: "杨高中路", Order: 26},
		{ID: "fangdian_road", Name: "芳甸路", Order: 27},
		{ID: "biyun_road", Name: "碧云路", Order: 28},
		{ID: "pingdu_road", Name: "平度路", Order: 29},
		{ID: "jinqiao_9", Name: "金桥", Order: 30},
		{ID: "jinji_road_9", Name: "金吉路", Order: 31},
		{ID: "jinhai_road_9", Name: "金海路", Order: 32},
		{ID: "gutang_road", Name: "顾唐路", Order: 33},
		{ID: "minlei_road", Name: "民雷路", Order: 34},
		{ID: "caolu_9", Name: "曹路", Order: 35},
	},
	"10": {
		{ID: "hangzhong_road", Name: "航中路", Order: 1},
		{ID: "ziteng_road", Name: "紫藤路", Order: 2},
		{ID: "longbai_xincun", Name: "龙柏新村", Order: 3},
		{ID: "shanghai_zoo_10", Name: "上海动物园", Order: 4},
		{ID: "longxi_road_10", Name: "龙溪路", Order: 5},
		{ID: "shuicheng_road_10", Name: "水城路", Order: 6},
		{ID: "yili_road_10", Name: "伊犁路", Order: 7},
		{ID: "songyuan_road_10", Name: "宋园路", Order: 8},
		{ID: "hongqiao_road_10", Name: "虹桥路", Order: 9},
		{ID: "jiaotong_univ_10", Name: "交通大学", Order: 10},
		{ID: "shanghai_library_10", Name: "上海图书馆", Order: 11},
		{ID: "shaanxi_south_10", Name: "陕西南路", Order: 12},
		{ID: "xintiandi_10", Name: "新天地", Order: 13},
		{ID: "laoximen_10", Name: "老西门", Order: 14},
		{ID: "yuyuan_10", Name: "豫园", Order: 15},
		{ID: "nanjing_east_10", Name: "南京东路", Order: 16},
		{ID: "tiantong_road_10", Name: "天潼路", Order: 17},
		{ID: "north_sichuan_road_10", Name: "四川北路", Order: 18},
		{ID: "hailun_road_10", Name: "海伦路", Order: 19},
		{ID: "youdian_xincun", Name: "邮电新村", Order: 20},
		{ID: "siping_road_10", Name: "四平路", Order: 21},
		{ID: "tongji_university_10", Name: "同济大学", Order: 22},
		{ID: "guoquan_road", Name: "国权路", Order: 23},
		{ID: "wujiaochang_10", Name: "五角场", Order: 24},
		{ID: "jiangwan_stadium_10", Name: "江湾体育场", Order: 25},
		{ID: "sanmen_road_10", Name: "三门路", Order: 26},
		{ID: "yingao_east_road", Name: "殷高东路", Order: 27},
		{ID: "xinjiangwancheng", Name: "新江湾城", Order: 28},
		{ID: "jilong_road_10", Name: "基隆路", Order: 29},
		{ID: "gangcheng_road_10", Name: "港城路", Order: 30},
	},
	"11": {
		{ID: "jiading_north_11", Name: "嘉定北", Order: 1},
		{ID: "jiading_west_11", Name: "嘉定西", Order: 2},
		{ID: "shanghai_circuit_11", Name: "上海赛车场", Order: 3},
		{ID: "antaing_11", Name: "安亭", Order: 4},
		{ID: "nanxiang_11", Name: "南翔", Order: 5},
		{ID: "malu_11", Name: "马陆", Order: 6},
		{ID: "jiading_newcity_11", Name: "嘉定新城", Order: 7},
		{ID: "zhenxin_xincun", Name: "真新新村", Order: 8},
		{ID: "qilianshan_road_11", Name: "祁连山路", Order: 9},
		{ID: "wuwei_road", Name: "武威路", Order: 10},
		{ID: "caoyang_road_11", Name: "曹杨路", Order: 11},
		{ID: "fengqiao_road", Name: "枫桥路", Order: 12},
		{ID: "zhenru_11", Name: "真如", Order: 13},
		{ID: "longde_road_11", Name: "隆德路", Order: 14},
		{ID: "jiangsu_road_11", Name: "江苏路", Order: 15},
		{ID: "jiaotong_univ_11", Name: "交通大学", Order: 16},
		{ID: "xujiahui_11", Name: "徐家汇", Order: 17},
		{ID: "longhua_11", Name: "龙华", Order: 18},
		{ID: "yunjin_road_11", Name: "云锦路", Order: 19},
		{ID: "longyao_road_11", Name: "龙耀路", Order: 20},
		{ID: "oriental_sports_11", Name: "东方体育中心", Order: 21},
		{ID: "sanlin_11", Name: "三林", Order: 22},
		{ID: "pujian_road_11", Name: "浦建路", Order: 23},
		{ID: "luoshan_road_11", Name: "罗山路", Order: 24},
		{ID: "xiuyan_road", Name: "秀沿路", Order: 25},
		{ID: "kangxin_highway", Name: "康新公路", Order: 26},
		{ID: "disney_resort", Name: "迪士尼", Order: 27},
	},
	"12": {
		{ID: "qixin_road", Name: "七莘路", Order: 1},
		{ID: "hongxin_road", Name: "虹莘路", Order: 2},
		{ID: "gudai_road", Name: "顾戴路", Order: 3},
		{ID: "donglan_road", Name: "东兰路", Order: 4},
		{ID: "hongmei_road", Name: "虹梅路", Order: 5},
		{ID: "guilin_road_12", Name: "桂林路", Order: 6},
		{ID: "caobao_road_12", Name: "漕宝路", Order: 7},
		{ID: "longcao_road_12", Name: "龙漕路", Order: 8},
		{ID: "longhua_12", Name: "龙华", Order: 9},
		{ID: "longhua_mid_12", Name: "龙华中路", Order: 10},
		{ID: "damuqiao_road_12", Name: "大木桥路", Order: 11},
		{ID: "jiashan_road_12", Name: "嘉善路", Order: 12},
		{ID: "shaanxi_south_12", Name: "陕西南路", Order: 13},
		{ID: "nanjing_west_12", Name: "南京西路", Order: 14},
		{ID: "hanzhong_road_12", Name: "汉中路", Order: 15},
		{ID: "qufu_road_12", Name: "曲阜路", Order: 16},
		{ID: "tiantong_road_12", Name: "天潼路", Order: 17},
		{ID: "guoji_ferry", Name: "国际客运中心", Order: 18},
		{ID: "tilanqiao", Name: "提篮桥", Order: 19},
		{ID: "dalian_road_12", Name: "大连路", Order: 20},
		{ID: "jiangpu_park_12", Name: "江浦公园", Order: 21},
		{ID: "ningguo_road_12", Name: "宁国路", Order: 22},
		{ID: "longchang_road_12", Name: "隆昌路", Order: 23},
		{ID: "aiguo_road", Name: "爱国路", Order: 24},
		{ID: "fuxing_island_12", Name: "复兴岛", Order: 25},
		{ID: "donglu_road", Name: "东陆路", Order: 26},
		{ID: "jufeng_road_12", Name: "巨峰路", Order: 27},
		{ID: "yanggao_north_12", Name: "杨高北路", Order: 28},
		{ID: "jinjing_road", Name: "金京路", Order: 29},
		{ID: "shenjiang_road_12", Name: "申江路", Order: 30},
		{ID: "jinhai_road_12", Name: "金海路", Order: 31},
	},
	"13": {
		{ID: "jinyun_road", Name: "金运路", Order: 1},
		{ID: "baisha_road", Name: "金沙江西路", Order: 2},
		{ID: "fengzhuang", Name: "丰庄", Order: 3},
		{ID: "qilianshan_south_13", Name: "祁连山南路", Order: 4},
		{ID: "zhenbei_road", Name: "真北路", Order: 5},
		{ID: "daduhui_road", Name: "大渡河路", Order: 6},
		{ID: "jinshajiang_road_13", Name: "金沙江路", Order: 7},
		{ID: "longde_road_13", Name: "隆德路", Order: 8},
		{ID: "wuning_road", Name: "武宁路", Order: 9},
		{ID: "changshou_road_13", Name: "长寿路", Order: 10},
		{ID: "jiangning_road", Name: "江宁路", Order: 11},
		{ID: "hanzhong_road_13", Name: "汉中路", Order: 12},
		{ID: "natural_history", Name: "自然博物馆", Order: 13},
		{ID: "nanjing_west_13", Name: "南京西路", Order: 14},
		{ID: "huaihai_mid_road", Name: "淮海中路", Order: 15},
		{ID: "xintiandi_13", Name: "新天地", Order: 16},
		{ID: "malu_road_13", Name: "马当路", Order: 17},
		{ID: "shibo_avenue", Name: "世博大道", Order: 18},
		{ID: "shibo_museum", Name: "世博会博物馆", Order: 19},
		{ID: "changqing_road_13", Name: "长清路", Order: 20},
		{ID: "chengshan_road_13", Name: "成山路", Order: 21},
		{ID: "dongming_road_13", Name: "东明路", Order: 22},
		{ID: "huapeng_road", Name: "华鹏路", Order: 23},
		{ID: "xianan_road", Name: "下南路", Order: 24},
		{ID: "beicai_13", Name: "北蔡", Order: 25},
		{ID: "chenchun_road", Name: "陈春路", Order: 26},
		{ID: "lianxi_road", Name: "莲溪路", Order: 27},
		{ID: "zhongke_road", Name: "中科路", Order: 28},
		{ID: "xuelin_road", Name: "学林路", Order: 29},
		{ID: "zhangjiang_road_13", Name: "张江路", Order: 30},
	},
	"14": {
		{ID: "fengbang", Name: "封浜", Order: 1},
		{ID: "lexiu_road", Name: "乐秀路", Order: 2},
		{ID: "lintao_road", Name: "临洮路", Order: 3},
		{ID: "jiayi_road", Name: "嘉怡路", Order: 4},
		{ID: "dingbian_road", Name: "定边路", Order: 5},
		{ID: "zhenxin_xincun_14", Name: "真新新村", Order: 6},
		{ID: "zhenguang_road", Name: "真光路", Order: 7},
		{ID: "tongchuan_road_14", Name: "铜川路", Order: 8},
		{ID: "zhenru_14", Name: "真如", Order: 9},
		{ID: "zhongning_road", Name: "中宁路", Order: 10},
		{ID: "caoyang_road_14", Name: "曹杨路", Order: 11},
		{ID: "wuning_road_14", Name: "武宁路", Order: 12},
		{ID: "wuding_road", Name: "武定路", Order: 13},
		{ID: "jingan_temple_14", Name: "静安寺", Order: 14},
		{ID: "huangpi_south_14", Name: "黄陂南路", Order: 15},
		{ID: "dashijie_14", Name: "大世界", Order: 16},
		{ID: "yuyuan_14", Name: "豫园", Order: 17},
		{ID: "lujiazui_14", Name: "陆家嘴", Order: 18},
		{ID: "pudong_avenue_14", Name: "浦东大道", Order: 19},
		{ID: "yuanshen_road_14", Name: "源深路", Order: 20},
		{ID: "changyi_road", Name: "昌邑路", Order: 21},
		{ID: "yunshan_road_14", Name: "云山路", Order: 22},
		{ID: "lantian_road_14", Name: "蓝天路", Order: 23},
		{ID: "huangyang_road", Name: "黄杨路", Order: 24},
		{ID: "jinqiao_14", Name: "金桥", Order: 25},
		{ID: "guiqiao_road", Name: "桂桥路", Order: 26},
	},
	"15": {
		{ID: "gucun_park_15", Name: "顾村公园", Order: 1},
		{ID: "jinqiu_road", Name: "锦秋路", Order: 2},
		{ID: "fengxiang_road", Name: "丰翔路", Order: 3},
		{ID: "nanda_road", Name: "南大路", Order: 4},
		{ID: "qilianshan_road_15", Name: "祁安路", Order: 5},
		{ID: "gulang_road", Name: "古浪路", Order: 6},
		{ID: "wunan_road", Name: "武南路", Order: 7},
		{ID: "shanghai_west_15", Name: "上海西站", Order: 8},
		{ID: "tongchuan_road_15", Name: "铜川路", Order: 9},
		{ID: "meiling_north", Name: "梅岭北路", Order: 10},
		{ID: "daduhui_road_15", Name: "大渡河路", Order: 11},
		{ID: "changfeng_park", Name: "长风公园", Order: 12},
		{ID: "loushanguan_15", Name: "娄山关路", Order: 13},
		{ID: "hongbaoshi_road", Name: "红宝石路", Order: 14},
		{ID: "yaohong_road", Name: "姚虹路", Order: 15},
		{ID: "wuzhong_road", Name: "吴中路", Order: 16},
		{ID: "guilin_road_15", Name: "桂林路", Order: 17},
		{ID: "guilin_park", Name: "桂林公园", Order: 18},
		{ID: "shanghai_south_15", Name: "上海南站", Order: 19},
		{ID: "huadong_univ", Name: "华东理工大学", Order: 20},
		{ID: "luoxiu_road", Name: "罗秀路", Order: 21},
		{ID: "zhumei_road", Name: "朱梅路", Order: 22},
		{ID: "hongmei_south", Name: "虹梅南路", Order: 23},
		{ID: "jingxi_road", Name: "景西路", Order: 24},
		{ID: "shuguang_road", Name: "曙建路", Order: 25},
		{ID: "shuangbai_road", Name: "双柏路", Order: 26},
		{ID: "yuanjiang_road", Name: "元江路", Order: 27},
		{ID: "yongde_road", Name: "永德路", Order: 28},
		{ID: "zizhu_zone", Name: "紫竹高新区", Order: 29},
	},
	"16": {
		{ID: "longyang_road_16", Name: "龙阳路", Order: 1},
		{ID: "huaxia_mid", Name: "华夏中路", Order: 2},
		{ID: "luoshan_road_16", Name: "罗山路", Order: 3},
		{ID: "zhoupudong", Name: "周浦东", Order: 4},
		{ID: "heshahangcheng", Name: "鹤沙航城", Order: 5},
		{ID: "hangtou_east", Name: "航头东", Order: 6},
		{ID: "xinchang_16", Name: "新场", Order: 7},
		{ID: "wild_animal_park", Name: "野生动物园", Order: 8},
		{ID: "huinan_16", Name: "惠南", Order: 9},
		{ID: "huinan_east", Name: "惠南东", Order: 10},
		{ID: "shuyuan", Name: "书院", Order: 11},
		{ID: "lingang_avenue", Name: "临港大道", Order: 12},
		{ID: "dishui_lake", Name: "滴水湖", Order: 13},
	},
	"17": {
		{ID: "hongqiao_railway_17", Name: "虹桥火车站", Order: 1},
		{ID: "zhuguang_road", Name: "诸光路", Order: 2},
		{ID: "panlong_road", Name: "蟠龙路", Order: 3},
		{ID: "xuying_road", Name: "徐盈路", Order: 4},
		{ID: "xujing_beicheng", Name: "徐泾北城", Order: 5},
		{ID: "jiading_zhonglu", Name: "嘉松中路", Order: 6},
		{ID: "zhaoxiang", Name: "赵巷", Order: 7},
		{ID: "huijin_road", Name: "汇金路", Order: 8},
		{ID: "qingpu_xincheng", Name: "青浦新城", Order: 9},
		{ID: "caoying_road", Name: "漕盈路", Order: 10},
		{ID: "dianshanhu_avenue", Name: "淀山湖大道", Order: 11},
		{ID: "zhujiajiao", Name: "朱家角", Order: 12},
		{ID: "oriental_land", Name: "东方绿舟", Order: 13},
	},
	"18": {
		{ID: "changjiang_south_18", Name: "长江南路", Order: 1},
		{ID: "yingao_road_18", Name: "殷高路", Order: 2},
		{ID: "shanghai_finance_univ", Name: "上海财经大学", Order: 3},
		{ID: "fudan_univ", Name: "复旦大学", Order: 4},
		{ID: "guoquan_road_18", Name: "国权路", Order: 5},
		{ID: "fushun_road", Name: "抚顺路", Order: 6},
		{ID: "jiangpu_road_18", Name: "江浦路", Order: 7},
		{ID: "jiangpu_park_18", Name: "江浦公园", Order: 8},
		{ID: "pingliang_road", Name: "平凉路", Order: 9},
		{ID: "danyang_road", Name: "丹阳路", Order: 10},
		{ID: "changyi_road_18", Name: "昌邑路", Order: 11},
		{ID: "minsheng_road_18", Name: "民生路", Order: 12},
		{ID: "yanggao_mid_18", Name: "杨高中路", Order: 13},
		{ID: "yingchun_road", Name: "迎春路", Order: 14},
		{ID: "longyang_road_18", Name: "龙阳路", Order: 15},
		{ID: "fangxin_road", Name: "芳芯路", Order: 16},
		{ID: "beizhong_road", Name: "北中路", Order: 17},
		{ID: "lianxi_road_18", Name: "莲溪路", Order: 18},
		{ID: "yulan_road", Name: "御兰路", Order: 19},
		{ID: "kangqiao_18", Name: "康桥", Order: 20},
		{ID: "zhoudong", Name: "周东路", Order: 21},
		{ID: "shenmei_road", Name: "沈梅路", Order: 22},
		{ID: "xiasha", Name: "下沙", Order: 23},
		{ID: "hangtou_18", Name: "航头", Order: 24},
	},
}

var metroNetworkStationIDToName = buildMetroNetworkStationIDToName()
var metroNetworkStationNameToID = buildMetroNetworkStationNameToID()

func buildMetroNetworkStationIDToName() map[string]string {
	result := make(map[string]string)
	for _, stations := range metroNetworkLines {
		for _, station := range stations {
			result[station.ID] = station.Name
		}
	}
	return result
}

func buildMetroNetworkStationNameToID() map[string]string {
	result := make(map[string]string)
	for _, stations := range metroNetworkLines {
		for _, station := range stations {
			if _, exists := result[station.Name]; !exists {
				result[station.Name] = station.ID
			}
		}
	}
	return result
}

func normalizeNetworkMetroLineID(lineID string) string {
	lineID = strings.TrimSpace(lineID)
	lineID = strings.TrimPrefix(lineID, "shanghai_metro_line_")
	lineID = strings.TrimPrefix(lineID, "line_")
	return lineID
}

func metroNetworkLine(lineID string) (models.MetroLine, bool) {
	normalized := normalizeNetworkMetroLineID(lineID)
	name, ok := metroNetworkLineNames[normalized]
	if !ok {
		return models.MetroLine{}, false
	}
	color := metroNetworkLineColors[normalized]
	desc := "????" + name
	return models.MetroLine{
		LineID:      normalized,
		LineName:    name,
		City:        "??",
		ColorHex:    &color,
		Description: &desc,
	}, true
}

func MetroNetworkLineSummaries() []MetroNetworkLineSummary {
	orderedLineIDs := []string{"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18"}
	lines := make([]MetroNetworkLineSummary, 0, len(orderedLineIDs))
	for _, lineID := range orderedLineIDs {
		stations := metroNetworkLines[lineID]
		if len(stations) == 0 {
			continue
		}
		stationSummaries := make([]MetroNetworkStationSummary, 0, len(stations))
		for _, station := range stations {
			stationSummaries = append(stationSummaries, MetroNetworkStationSummary{
				ID:    station.ID,
				Name:  station.Name,
				Order: station.Order,
			})
		}
		lines = append(lines, MetroNetworkLineSummary{
			ID:            lineID,
			Name:          metroNetworkLineNames[lineID],
			City:          "上海",
			Color:         metroNetworkLineColors[lineID],
			Directions:    []string{stations[0].Name, stations[len(stations)-1].Name},
			FirstTrain:    metroNetworkFirstTrain(lineID),
			LastTrain:     metroNetworkLastTrain(lineID),
			Interval:      metroNetworkInterval(lineID),
			CrowdingLevel: metroNetworkCrowding(lineID),
			StationCount:  len(stations),
			Stations:      stationSummaries,
		})
	}
	return lines
}

func MetroNetworkValidate() (map[string]int, []string) {
	counts := map[string]int{
		"network_lines":             len(metroNetworkLines),
		"network_line_station_rows": 0,
	}
	errors := []string{}
	for lineID, stations := range metroNetworkLines {
		if len(stations) == 0 {
			errors = append(errors, "line "+lineID+" has no stations")
			continue
		}
		counts["network_line_station_rows"] += len(stations)
		seenOrders := map[int]bool{}
		seenNames := map[string]bool{}
		for _, station := range stations {
			if station.Name == "" || station.ID == "" {
				errors = append(errors, "line "+lineID+" has empty station fields")
			}
			if seenOrders[station.Order] {
				errors = append(errors, "line "+lineID+" has duplicate station order")
			}
			seenOrders[station.Order] = true
			if seenNames[station.Name] {
				errors = append(errors, "line "+lineID+" has duplicate station "+station.Name)
			}
			seenNames[station.Name] = true
		}
	}
	if len(metroNetworkLines) < 18 {
		errors = append(errors, "network has fewer than 18 metro lines")
	}
	return counts, errors
}

func metroNetworkFirstTrain(lineID string) string {
	switch lineID {
	case "16", "17":
		return "06:00"
	default:
		return "05:30"
	}
}

func metroNetworkLastTrain(lineID string) string {
	switch lineID {
	case "16", "17":
		return "22:30"
	default:
		return "23:00"
	}
}

func metroNetworkInterval(lineID string) string {
	switch lineID {
	case "1", "2", "8", "10":
		return "3-5分钟"
	case "16", "17":
		return "6-10分钟"
	default:
		return "4-8分钟"
	}
}

func metroNetworkCrowding(lineID string) string {
	switch lineID {
	case "1", "2", "8", "10":
		return "高峰较拥挤"
	case "16", "17":
		return "平峰较舒适"
	default:
		return "中等"
	}
}

func metroNetworkStationByName(name string) (models.Station, bool) {
	name = strings.TrimSpace(name)
	if id, ok := metroNetworkStationNameToID[name]; ok {
		return models.Station{StationID: id, StationName: name, City: "??", StationType: "???"}, true
	}
	for stationName, id := range metroNetworkStationNameToID {
		if strings.Contains(stationName, name) || strings.Contains(name, stationName) {
			return models.Station{StationID: id, StationName: stationName, City: "??", StationType: "???"}, true
		}
	}
	return models.Station{}, false
}

func metroNetworkStationName(stationID string, fallback string) string {
	if name, ok := metroNetworkStationIDToName[stationID]; ok {
		return name
	}
	return fallback
}

func MetroNetworkStationNameForID(stationID string) string {
	return metroNetworkStationName(stationID, "")
}

func metroNetworkLineStations(stationID string, stationName string) []models.LineStation {
	stationName = metroNetworkStationName(stationID, stationName)
	var result []models.LineStation
	for lineID, stations := range metroNetworkLines {
		for _, station := range stations {
			if station.Name == stationName {
				result = append(result, models.LineStation{
					LineID:       lineID,
					StationID:    stationID,
					Direction:    "both",
					StationOrder: station.Order,
					IsTransfer:   metroNetworkIsTransferStation(stationName),
				})
			}
		}
	}
	return result
}

func metroNetworkIsTransferStation(stationName string) bool {
	count := 0
	for _, stations := range metroNetworkLines {
		for _, station := range stations {
			if station.Name == stationName {
				count++
				break
			}
		}
	}
	return count > 1
}

func metroNetworkCommonTransferStations(lineID1 string, lineID2 string) []string {
	lineID1 = normalizeNetworkMetroLineID(lineID1)
	lineID2 = normalizeNetworkMetroLineID(lineID2)
	if lineID1 == lineID2 {
		return nil
	}
	first := make(map[string]bool)
	for _, station := range metroNetworkLines[lineID1] {
		if metroNetworkIsTransferStation(station.Name) {
			first[station.Name] = true
		}
	}
	var result []string
	seen := make(map[string]bool)
	for _, station := range metroNetworkLines[lineID2] {
		if first[station.Name] && !seen[station.Name] {
			result = append(result, station.Name)
			seen[station.Name] = true
		}
	}
	return result
}

func metroNetworkOrder(lineID string, station string) (int, bool) {
	lineID = normalizeNetworkMetroLineID(lineID)
	station = metroNetworkStationName(station, station)
	for _, item := range metroNetworkLines[lineID] {
		if item.Name == station || item.ID == station {
			return item.Order, true
		}
	}
	return 0, false
}
