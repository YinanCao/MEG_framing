if     press_key(LH)
        rsp = 'LH';
        rsp_code = 1;
        rsp_trig = info.resp_LH_trig;
elseif press_key(RH)
        rsp = 'RH';
        rsp_code = 2;
        rsp_trig = info.resp_RH_trig;
elseif press_key(LF)
        rsp = 'LF';
        rsp_code = 3;
        rsp_trig = info.resp_LF_trig;
elseif press_key(RF)
        rsp = 'RF';
        rsp_code = 4;
        rsp_trig = info.resp_RF_trig;
else
        rsp = 'I';
        rsp_code = nan;
        rsp_trig = info.resp_invalid_trig;
end

trig_id = rsp_trig;
trigger(trig_id); disp(['response trig == ',num2str(trig_id)])
    
if info.ET
    Eyelink('message', num2str(rsp_trig));
end

