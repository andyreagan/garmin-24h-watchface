import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TwentyFourHourApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new TwentyFourHourView() ];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}

function getApp() as TwentyFourHourApp {
    return Application.getApp() as TwentyFourHourApp;
}
