import Toybox.Lang;
import Toybox.WatchUi;
using Untis4GarminActions as Actions;

class Untis4GarminDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new Untis4GarminMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onNextPage() as Boolean {
        Actions.nextLesson();
        return true;
    }

    function onPreviousPage() as Boolean {
        Actions.previousLesson();
        return true;
    }
}