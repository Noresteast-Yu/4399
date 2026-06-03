package models

type Station struct {
	ID           int     `json:"id"`
	StationID    string  `json:"station_id"`
	StationName  string  `json:"station_name"`
	StationAlias *string `json:"station_alias"`
	City         string  `json:"city"`
	District     *string `json:"district"`
	StationType  string  `json:"station_type"`
	Description  *string `json:"description"`
}

type MetroLine struct {
	ID          int     `json:"id"`
	LineID      string  `json:"line_id"`
	LineName    string  `json:"line_name"`
	City        string  `json:"city"`
	ColorName   *string `json:"color_name"`
	ColorHex    *string `json:"color_hex"`
	Description *string `json:"description"`
}

type LineStation struct {
	ID           int     `json:"id"`
	LineID       string  `json:"line_id"`
	StationID    string  `json:"station_id"`
	Direction    string  `json:"direction"`
	StationOrder int     `json:"station_order"`
	IsTransfer   bool    `json:"is_transfer"`
	PlatformTip  *string `json:"platform_tip"`
}

type TransferRule struct {
	ID                 int     `json:"id"`
	RuleID             string  `json:"rule_id"`
	OriginStationID    string  `json:"origin_station_id"`
	LineID             string  `json:"line_id"`
	TargetStationID    string  `json:"target_station_id"`
	Direction          string  `json:"direction"`
	StopsCount         int     `json:"stops_count"`
	EstimatedMinutes   int     `json:"estimated_minutes"`
	CarriageSuggestion *string `json:"carriage_suggestion"`
	TransferTip        *string `json:"transfer_tip"`
	DataLevel          string  `json:"data_level"`
}

type StationFacility struct {
	ID                    int    `json:"id"`
	StationID             string `json:"station_id"`
	HasElevator           bool   `json:"has_elevator"`
	HasEscalator          bool   `json:"has_escalator"`
	HasWheelchairRamp     bool   `json:"has_wheelchair_ramp"`
	HasWideGate           bool   `json:"has_wide_gate"`
	HasAccessibleRestroom bool   `json:"has_accessible_restroom"`
	HasBlindPath          bool   `json:"has_blind_path"`
	ElevatorCount         int    `json:"elevator_count"`
	ElevatorLocation      string `json:"elevator_location"`
	EscalatorCount        int    `json:"escalator_count"`
	RestroomLocation      string `json:"restroom_location"`
	HasRestroomInPaid     bool   `json:"has_restroom_in_paid"`
	HasRestroomOutside    bool   `json:"has_restroom_outside"`
	HasMotherBabyRoom     bool   `json:"has_mother_baby_room"`
	HasThirdBathroom      bool   `json:"has_third_bathroom"`
	HasAED                bool   `json:"has_aed"`
	HasServiceCenter      bool   `json:"has_service_center"`
	FacilityNote          string `json:"facility_note"`
}
