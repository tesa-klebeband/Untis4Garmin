import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class Untis4GarminApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) {
    }

    function onStop(state as Dictionary?) {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new Untis4GarminView(), new Untis4GarminDelegate()];
    }

    function onSettingsChanged() {
        settingsChanged = true;
        WatchUi.requestUpdate();
    }
}

function getApp() {
    return Application.getApp() as Untis4GarminApp;
}