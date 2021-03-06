--
-- (C) 2019-21 - ntop.org
--

local json = require ("dkjson")
local user_scripts = require ("user_scripts")
local alert_consts = require("alert_consts")
local alerts_api = require "alerts_api"
local alert_severities = require "alert_severities"

-- #################################################################

local script = {
  -- NOTE: hooks defined below
  hooks = {},

  is_alert = true,

  default_value = {
    severity = alert_severities.warning,
  },

  gui = {
    i18n_title = "flow_callbacks_config.ext_alert",
    i18n_description = "flow_callbacks_config.ext_alert_description",
  }
}

-- #################################################################

local function checkExternalAlert(config)

  -- Check for external alert (clear on read, thus it will not be
  -- returned in the next call)
  local info_json = flow.retrieveExternalAlertInfo()

  if(info_json ~= nil) then
    -- Got an alert in JSON format, decoding
    local info = json.decode(info_json)

    if info ~= nil then
      -- Default scores used when no IDS utils is available
      local flow_score = 100
      local cli_score = 100
      local srv_score = 100

      local alert = alert_consts.alert_types.external_alert.new(
        info
      )
        
      if ntop.isEnterpriseM() then
        local ids_utils = require("ids_utils")

        if ids_utils and alert.alert_type_params and
           alert.alert_type_params.source == "suricata" then
           local fs, cs, ss = ids_utils.computeScore(alert.alert_type_params)
           flow_score = fs
           cli_score = cs
           srv_score = ss
        end
      end

      -- Trigger flow alert
      alert:set_severity(config.severity)

      alert:trigger_status(cli_score, srv_score, flow_score)
    end
  end
end

-- #################################################################

function script.hooks.periodicUpdate(now, config)
   checkExternalAlert(config)
end

-- #################################################################

function script.hooks.flowEnd(now, config)
   checkExternalAlert(config)
end

-- #################################################################

return script
