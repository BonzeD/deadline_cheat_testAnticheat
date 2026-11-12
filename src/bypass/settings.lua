-- Explicitly allow only your controlled test PlaceIds. Empty means disabled.
return {
    BypassAllowedPlaceIds = {},
    BypassSpoofSpeed = 16,
    -- Exact path under ReplicatedStorage and exact first FireServer argument.
    -- Example for your own test place: {"LabEvents", "Detector"}, "TestFlag".
    BypassRemotePath = {},
    BypassRemoteFlag = "",
}
