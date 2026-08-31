%populate {
    object WiFi {
        object Radio {
{% for ( let Radio in BD.Radios ) : if (Radio.OperatingFrequency == "5GHz") : %}
            object '{{Radio.Alias}}' {
                /* 5GHz radio defaults matching reference hostapd config */
                parameter OperatingFrequencyBand = "5GHz";
                parameter RegulatoryDomain = "US";
                parameter Channel = 40;
                parameter OperatingChannelBandwidth = "160MHz";
                parameter BeaconPeriod = 100;
                parameter PreambleType = "short";
                parameter ExplicitBeamFormingEnabled = true;
                parameter ImplicitBeamFormingEnabled = true;
                parameter MultiUserMIMOEnabled = true;
                parameter MaxAssociatedDevices = 512;
                parameter PPEVPType = 3;
                parameter IEEE80211hEnabled = true;
                parameter ObssCoexistenceEnable = 0;
                object IEEE80211ax {
                    parameter BssColor = 31;
                }
                object ACS {
                    parameter ChannelList = "36-165";
                }
            }
{% endif; endfor; %}
        }
        object AccessPoint {
{% for ( let Itf in BD.Interfaces ) : if ( BDfn.isInterfaceWirelessAp(Itf.Name) ) : %}
{% let Radio = BDfn.getRadioForInterface(Itf.Name) %}
{% if (Radio && Radio.OperatingFrequency == "5GHz") : %}
            object '{{Itf.Alias}}' {
                /* 5GHz VAP defaults matching reference hostapd config */
                parameter SSIDAdvertisementEnabled = true;
                parameter WMMEnable = true;
                parameter UAPSDEnable = true;
                parameter WDSEnable = true;
                parameter MaxAssociatedDevices = 512;
                object Qbss {
                    parameter Enable = true;
                    parameter ChanUtilAvgPeriod = 600;
                    parameter BssLoadUpdatePeriod = 10;
                }
                object IEEE80211u {
                    parameter QoSMapSet = "0,0,2,16,1,1,255,255,18,22,24,38,40,40,44,46,48,56";
                }
                object Security {
                    parameter ModeEnabled = "WPA3-Personal";
                    parameter MFPConfig = "Required";
                    parameter KeyPassPhrase = "1234567890";
                }
            }
{% endif %}
{% endif; endfor; %}
        }
    }
}
