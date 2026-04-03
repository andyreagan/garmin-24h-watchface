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

    // Pre-loaded rotated number bitmaps
    private var _numBitmaps as Array<BitmapResource or Null> = new Array<BitmapResource or Null>[24];

    // Month abbreviations
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

        // Load rotated number bitmaps
        _numBitmaps[0] = WatchUi.loadResource(Rez.Drawables.Num00) as BitmapResource;
        _numBitmaps[1] = WatchUi.loadResource(Rez.Drawables.Num01) as BitmapResource;
        _numBitmaps[2] = WatchUi.loadResource(Rez.Drawables.Num02) as BitmapResource;
        _numBitmaps[3] = WatchUi.loadResource(Rez.Drawables.Num03) as BitmapResource;
        _numBitmaps[4] = WatchUi.loadResource(Rez.Drawables.Num04) as BitmapResource;
        _numBitmaps[5] = WatchUi.loadResource(Rez.Drawables.Num05) as BitmapResource;
        _numBitmaps[6] = WatchUi.loadResource(Rez.Drawables.Num06) as BitmapResource;
        _numBitmaps[7] = WatchUi.loadResource(Rez.Drawables.Num07) as BitmapResource;
        _numBitmaps[8] = WatchUi.loadResource(Rez.Drawables.Num08) as BitmapResource;
        _numBitmaps[9] = WatchUi.loadResource(Rez.Drawables.Num09) as BitmapResource;
        _numBitmaps[10] = WatchUi.loadResource(Rez.Drawables.Num10) as BitmapResource;
        _numBitmaps[11] = WatchUi.loadResource(Rez.Drawables.Num11) as BitmapResource;
        _numBitmaps[12] = WatchUi.loadResource(Rez.Drawables.Num12) as BitmapResource;
        _numBitmaps[13] = WatchUi.loadResource(Rez.Drawables.Num13) as BitmapResource;
        _numBitmaps[14] = WatchUi.loadResource(Rez.Drawables.Num14) as BitmapResource;
        _numBitmaps[15] = WatchUi.loadResource(Rez.Drawables.Num15) as BitmapResource;
        _numBitmaps[16] = WatchUi.loadResource(Rez.Drawables.Num16) as BitmapResource;
        _numBitmaps[17] = WatchUi.loadResource(Rez.Drawables.Num17) as BitmapResource;
        _numBitmaps[18] = WatchUi.loadResource(Rez.Drawables.Num18) as BitmapResource;
        _numBitmaps[19] = WatchUi.loadResource(Rez.Drawables.Num19) as BitmapResource;
        _numBitmaps[20] = WatchUi.loadResource(Rez.Drawables.Num20) as BitmapResource;
        _numBitmaps[21] = WatchUi.loadResource(Rez.Drawables.Num21) as BitmapResource;
        _numBitmaps[22] = WatchUi.loadResource(Rez.Drawables.Num22) as BitmapResource;
        _numBitmaps[23] = WatchUi.loadResource(Rez.Drawables.Num23) as BitmapResource;
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var min = clockTime.min;

        drawDial(dc);

        var showMinuteHand = Application.Properties.getValue("ShowMinuteHand") as Boolean;
        if (showMinuteHand) {
            drawMinuteHand(dc, min);
        }
        drawHourHand(dc, hour, min);

        // Center dot
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, 3);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, 1);

        var showDate = Application.Properties.getValue("ShowDate") as Boolean;
        if (showDate) {
            drawDate(dc);
        }
    }

    // Get x,y at a given radius from center for a 24h position
    private function getXY(hourFloat as Float, r as Number) as Array<Number> {
        var angleDeg = (hourFloat * 15.0) - 90.0;
        var angleRad = Math.toRadians(angleDeg);
        var x = _centerX + (r * Math.cos(angleRad)).toNumber();
        var y = _centerY + (r * Math.sin(angleRad)).toNumber();
        return [x, y];
    }

    private function drawDial(dc as Dc) as Void {
        // Layout (from edge inward, radius=130 on 260x260):
        //   Number bitmaps: centered at r=122 (~8px from edge)
        //   Tick outer: r=114 (16px from edge)
        //   Hour tick inner: r=100 (30px from edge) -> 14px long
        //   Quarter tick inner: r=107 (23px from edge) -> 7px long

        var numberRadius = _radius - 8;
        var tickOuter = _radius - 18;
        var hourTickInner = _radius - 32;
        var quarterTickInner = _radius - 25;

        // Draw rotated number bitmaps on the outside
        for (var h = 0; h < 24; h++) {
            var bmp = _numBitmaps[h];
            if (bmp != null) {
                var pt = getXY(h.toFloat(), numberRadius);
                var bw = bmp.getWidth();
                var bh = bmp.getHeight();
                dc.drawBitmap(pt[0] - bw / 2, pt[1] - bh / 2, bmp);
            }
        }

        // Draw tick marks every 15 minutes (96 ticks)
        dc.setPenWidth(1);
        for (var i = 0; i < 96; i++) {
            var hourFloat = i / 4.0;
            var isHour = (i % 4 == 0);

            var outerPt = getXY(hourFloat, tickOuter);

            if (isHour) {
                var innerPt = getXY(hourFloat, hourTickInner);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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
        var angleDeg = (hourFloat * 15.0) - 90.0;
        var angleRad = Math.toRadians(angleDeg);

        // Arrow tip reaches just to the inner end of the quarter ticks
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

        // Draw shaft
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(tailX, tailY, shaftEndX, shaftEndY);
        dc.setPenWidth(1);

        // Arrow head
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

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
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

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}
