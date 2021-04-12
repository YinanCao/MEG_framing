function  drawtext_realign(window, txt, sy, color, info)
[~, ~, textbounds] = DrawFormattedText(window, txt, 'center', 0, info.backgroundcolor);
DrawFormattedText(window, txt, textbounds(1)+info.lateral_offset, sy, color);
end