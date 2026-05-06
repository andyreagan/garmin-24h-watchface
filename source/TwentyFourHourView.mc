import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class TwentyFourHourView extends WatchUi.WatchFace {

    private var _centerX as Number = 0;
    private var _centerY as Number = 0;
    private var _radius as Number = 0;

    // Standard set: hour 0/24 at top.
    private var _numBitmapsStd as Array<BitmapResource or Null> = new Array<BitmapResource or Null>[24];
    // Noon-at-top set: hour 12 at top.
    private var _numBitmapsNoon as Array<BitmapResource or Null> = new Array<BitmapResource or Null>[24];

    // Cached per-frame so getXY/drawHourHand share the same orientation.
    private var _noonOffsetDeg as Float = 0.0;

    private var _monthNames as Array<String> = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        _centerX = w / 2;
        _centerY = h / 2;
        _radius = (w < h ? w : h) / 2;

        _numBitmapsStd[0] = WatchUi.loadResource(Rez.Drawables.Num00) as BitmapResource;
        _numBitmapsStd[1] = WatchUi.loadResource(Rez.Drawables.Num01) as BitmapResource;
        _numBitmapsStd[2] = WatchUi.loadResource(Rez.Drawables.Num02) as BitmapResource;
        _numBitmapsStd[3] = WatchUi.loadResource(Rez.Drawables.Num03) as BitmapResource;
        _numBitmapsStd[4] = WatchUi.loadResource(Rez.Drawables.Num04) as BitmapResource;
        _numBitmapsStd[5] = WatchUi.loadResource(Rez.Drawables.Num05) as BitmapResource;
        _numBitmapsStd[6] = WatchUi.loadResource(Rez.Drawables.Num06) as BitmapResource;
        _numBitmapsStd[7] = WatchUi.loadResource(Rez.Drawables.Num07) as BitmapResource;
        _numBitmapsStd[8] = WatchUi.loadResource(Rez.Drawables.Num08) as BitmapResource;
        _numBitmapsStd[9] = WatchUi.loadResource(Rez.Drawables.Num09) as BitmapResource;
        _numBitmapsStd[10] = WatchUi.loadResource(Rez.Drawables.Num10) as BitmapResource;
        _numBitmapsStd[11] = WatchUi.loadResource(Rez.Drawables.Num11) as BitmapResource;
        _numBitmapsStd[12] = WatchUi.loadResource(Rez.Drawables.Num12) as BitmapResource;
        _numBitmapsStd[13] = WatchUi.loadResource(Rez.Drawables.Num13) as BitmapResource;
        _numBitmapsStd[14] = WatchUi.loadResource(Rez.Drawables.Num14) as BitmapResource;
        _numBitmapsStd[15] = WatchUi.loadResource(Rez.Drawables.Num15) as BitmapResource;
        _numBitmapsStd[16] = WatchUi.loadResource(Rez.Drawables.Num16) as BitmapResource;
        _numBitmapsStd[17] = WatchUi.loadResource(Rez.Drawables.Num17) as BitmapResource;
        _numBitmapsStd[18] = WatchUi.loadResource(Rez.Drawables.Num18) as BitmapResource;
        _numBitmapsStd[19] = WatchUi.loadResource(Rez.Drawables.Num19) as BitmapResource;
        _numBitmapsStd[20] = WatchUi.loadResource(Rez.Drawables.Num20) as BitmapResource;
        _numBitmapsStd[21] = WatchUi.loadResource(Rez.Drawables.Num21) as BitmapResource;
        _numBitmapsStd[22] = WatchUi.loadResource(Rez.Drawables.Num22) as BitmapResource;
        _numBitmapsStd[23] = WatchUi.loadResource(Rez.Drawables.Num23) as BitmapResource;

        _numBitmapsNoon[0] = WatchUi.loadResource(Rez.Drawables.NumNoon00) as BitmapResource;
        _numBitmapsNoon[1] = WatchUi.loadResource(Rez.Drawables.NumNoon01) as BitmapResource;
        _numBitmapsNoon[2] = WatchUi.loadResource(Rez.Drawables.NumNoon02) as BitmapResource;
        _numBitmapsNoon[3] = WatchUi.loadResource(Rez.Drawables.NumNoon03) as BitmapResource;
        _numBitmapsNoon[4] = WatchUi.loadResource(Rez.Drawables.NumNoon04) as BitmapResource;
        _numBitmapsNoon[5] = WatchUi.loadResource(Rez.Drawables.NumNoon05) as BitmapResource;
        _numBitmapsNoon[6] = WatchUi.loadResource(Rez.Drawables.NumNoon06) as BitmapResource;
        _numBitmapsNoon[7] = WatchUi.loadResource(Rez.Drawables.NumNoon07) as BitmapResource;
        _numBitmapsNoon[8] = WatchUi.loadResource(Rez.Drawables.NumNoon08) as BitmapResource;
        _numBitmapsNoon[9] = WatchUi.loadResource(Rez.Drawables.NumNoon09) as BitmapResource;
        _numBitmapsNoon[10] = WatchUi.loadResource(Rez.Drawables.NumNoon10) as BitmapResource;
        _numBitmapsNoon[11] = WatchUi.loadResource(Rez.Drawables.NumNoon11) as BitmapResource;
        _numBitmapsNoon[12] = WatchUi.loadResource(Rez.Drawables.NumNoon12) as BitmapResource;
        _numBitmapsNoon[13] = WatchUi.loadResource(Rez.Drawables.NumNoon13) as BitmapResource;
        _numBitmapsNoon[14] = WatchUi.loadResource(Rez.Drawables.NumNoon14) as BitmapResource;
        _numBitmapsNoon[15] = WatchUi.loadResource(Rez.Drawables.NumNoon15) as BitmapResource;
        _numBitmapsNoon[16] = WatchUi.loadResource(Rez.Drawables.NumNoon16) as BitmapResource;
        _numBitmapsNoon[17] = WatchUi.loadResource(Rez.Drawables.NumNoon17) as BitmapResource;
        _numBitmapsNoon[18] = WatchUi.loadResource(Rez.Drawables.NumNoon18) as BitmapResource;
        _numBitmapsNoon[19] = WatchUi.loadResource(Rez.Drawables.NumNoon19) as BitmapResource;
        _numBitmapsNoon[20] = WatchUi.loadResource(Rez.Drawables.NumNoon20) as BitmapResource;
        _numBitmapsNoon[21] = WatchUi.loadResource(Rez.Drawables.NumNoon21) as BitmapResource;
        _numBitmapsNoon[22] = WatchUi.loadResource(Rez.Drawables.NumNoon22) as BitmapResource;
        _numBitmapsNoon[23] = WatchUi.loadResource(Rez.Drawables.NumNoon23) as BitmapResource;
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var min = clockTime.min;

        var noonAtTop = readBool("NoonAtTop", false);
        _noonOffsetDeg = noonAtTop ? 180.0 : 0.0;

        drawDial(dc, noonAtTop);

        if (readBool("ShowMinuteHand", true)) {
            drawMinuteHand(dc, min);
        }
        drawHourHand(dc, hour, min);

        // Center dot
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, 3);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, 1);

        if (readBool("ShowDate", true)) {
            drawDate(dc);
        }

        if (readBool("ShowBattery", false)) {
            drawBattery(dc);
        }
    }

    // Application.Properties.getValue() can return null in some sim states
    // even when a default is declared, so coerce to a known fallback.
    private function readBool(key as String, fallback as Boolean) as Boolean {
        var v = Application.Properties.getValue(key);
        if (v == null) { return fallback; }
        return v as Boolean;
    }

    private function readNumber(key as String, fallback as Number) as Number {
        var v = Application.Properties.getValue(key);
        if (v == null) { return fallback; }
        return v as Number;
    }

    private function getXY(hourFloat as Float, r as Number) as Array<Number> {
        var angleDeg = (hourFloat * 15.0) - 90.0 + _noonOffsetDeg;
        var angleRad = Math.toRadians(angleDeg);
        var x = _centerX + (r * Math.cos(angleRad)).toNumber();
        var y = _centerY + (r * Math.sin(angleRad)).toNumber();
        return [x, y];
    }

    private function highlightColor(idx as Number) as Number {
        if (idx == 1) { return Graphics.COLOR_YELLOW; }
        if (idx == 2) { return Graphics.COLOR_RED; }
        if (idx == 3) { return Graphics.COLOR_GREEN; }
        if (idx == 4) { return Graphics.COLOR_BLUE; }
        if (idx == 5) { return Graphics.COLOR_ORANGE; }
        return Graphics.COLOR_WHITE;
    }

    private function drawDial(dc as Dc, noonAtTop as Boolean) as Void {
        var numberRadius = _radius - 8;
        var tickOuter = _radius - 18;
        var hourTickInner = _radius - 32;
        var quarterTickInner = _radius - 25;

        var bitmaps = noonAtTop ? _numBitmapsNoon : _numBitmapsStd;

        for (var h = 0; h < 24; h++) {
            var bmp = bitmaps[h];
            if (bmp != null) {
                var pt = getXY(h.toFloat(), numberRadius);
                var bw = bmp.getWidth();
                var bh = bmp.getHeight();
                dc.drawBitmap(pt[0] - bw / 2, pt[1] - bh / 2, bmp);
            }
        }

        // 96 ticks every 15 min on the 24h dial. The 5-minute marks for the
        // 60-min minute hand land every 30°, which is every 8th tick here
        // (i.e., even-numbered hour positions).
        var fiveMinChoice = readNumber("FiveMinTickColor", 0);
        var fiveMinColor = highlightColor(fiveMinChoice);
        var highlightOn = (fiveMinChoice > 0);

        dc.setPenWidth(1);
        for (var i = 0; i < 96; i++) {
            var hourFloat = i / 4.0;
            var isHour = (i % 4 == 0);
            var isFiveMin = (i % 8 == 0);

            var outerPt = getXY(hourFloat, tickOuter);

            if (isHour) {
                var innerPt = getXY(hourFloat, hourTickInner);
                var color = (highlightOn && isFiveMin) ? fiveMinColor : Graphics.COLOR_WHITE;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(outerPt[0], outerPt[1], innerPt[0], innerPt[1]);
            } else {
                var innerPt = getXY(hourFloat, quarterTickInner);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(outerPt[0], outerPt[1], innerPt[0], innerPt[1]);
            }
        }
    }

    private function drawHourHand(dc as Dc, hour as Number, min as Number) as Void {
        var hourFloat = hour.toFloat() + min.toFloat() / 60.0;
        var angleDeg = (hourFloat * 15.0) - 90.0 + _noonOffsetDeg;
        var angleRad = Math.toRadians(angleDeg);

        var tipRadius = _radius - 26;
        var tailLength = 15;

        var arrowHeadLength = 10;
        var arrowHalfWidth = 4;

        var tipX = _centerX + (tipRadius * Math.cos(angleRad)).toNumber();
        var tipY = _centerY + (tipRadius * Math.sin(angleRad)).toNumber();

        var tailX = _centerX - (tailLength * Math.cos(angleRad)).toNumber();
        var tailY = _centerY - (tailLength * Math.sin(angleRad)).toNumber();

        var shaftEndRadius = tipRadius - arrowHeadLength;
        var shaftEndX = _centerX + (shaftEndRadius * Math.cos(angleRad)).toNumber();
        var shaftEndY = _centerY + (shaftEndRadius * Math.sin(angleRad)).toNumber();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(tailX, tailY, shaftEndX, shaftEndY);
        dc.setPenWidth(1);

        var perpRad = angleRad + Math.PI / 2.0;
        var cosPerp = Math.cos(perpRad);
        var sinPerp = Math.sin(perpRad);

        var wingLX = shaftEndX + (arrowHalfWidth * cosPerp).toNumber();
        var wingLY = shaftEndY + (arrowHalfWidth * sinPerp).toNumber();
        var wingRX = shaftEndX - (arrowHalfWidth * cosPerp).toNumber();
        var wingRY = shaftEndY - (arrowHalfWidth * sinPerp).toNumber();

        var arrowPts = new Array<[Numeric, Numeric]>[3];
        arrowPts[0] = [tipX, tipY];
        arrowPts[1] = [wingLX, wingLY];
        arrowPts[2] = [wingRX, wingRY];
        dc.fillPolygon(arrowPts);
    }

    private function drawMinuteHand(dc as Dc, min as Number) as Void {
        var angleDeg = (min.toFloat() * 6.0) - 90.0;
        var angleRad = Math.toRadians(angleDeg);

        var handLength = _radius - 50;
        var tailLength = 10;

        var tipX = _centerX + (handLength * Math.cos(angleRad)).toNumber();
        var tipY = _centerY + (handLength * Math.sin(angleRad)).toNumber();

        var tailX = _centerX - (tailLength * Math.cos(angleRad)).toNumber();
        var tailY = _centerY - (tailLength * Math.sin(angleRad)).toNumber();

        // Match the 5-min tick highlight color so the minute-reading UI moves
        // together; gray fallback when highlight is off.
        var fiveMinChoice = readNumber("FiveMinTickColor", 0);
        var color = (fiveMinChoice > 0) ? highlightColor(fiveMinChoice) : Graphics.COLOR_LT_GRAY;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(tailX, tailY, tipX, tipY);
        dc.setPenWidth(1);
    }

    private function drawDate(dc as Dc) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);

        var monthStr = _monthNames[info.month - 1];
        var dateStr = monthStr + " " + info.day.format("%d");

        var font = Graphics.FONT_XTINY;
        var textWidth = dc.getTextWidthInPixels(dateStr, font);
        var fontHeight = dc.getFontHeight(font);

        var dateY = _centerY + 40;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(
            _centerX - textWidth / 2 - 3,
            dateY - 1,
            textWidth + 6,
            fontHeight + 2
        );

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            dateY,
            font,
            dateStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawBattery(dc as Dc) as Void {
        var stats = System.getSystemStats();
        var pct = stats.battery.toNumber();
        var battStr = pct.format("%d") + "%";

        var font = Graphics.FONT_XTINY;
        var textWidth = dc.getTextWidthInPixels(battStr, font);
        var fontHeight = dc.getFontHeight(font);

        // Mirror the date placement: above center.
        var battY = _centerY - 40 - fontHeight;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(
            _centerX - textWidth / 2 - 3,
            battY - 1,
            textWidth + 6,
            fontHeight + 2
        );

        // Color-code low battery so a glance tells you state.
        var color = Graphics.COLOR_LT_GRAY;
        if (pct <= 10) {
            color = Graphics.COLOR_RED;
        } else if (pct <= 25) {
            color = Graphics.COLOR_YELLOW;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            battY,
            font,
            battStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}
