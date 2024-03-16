import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
using Untis4GarminActions as Actions;

class Untis4GarminMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        switch (item) {
            case :NextDay:
                Actions.nextDay();
                break;

            case :PreviousDay:
                Actions.previousDay();
                break;

            case :NextLesson:
                Actions.nextLesson();
                break;

            case :PreviousLesson:
                Actions.previousLesson();
                break;

            case :Refresh:
                Actions.refresh();
                break;
            
            case :Today:
                Actions.today();
                break;
        }
    }
}