import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;

var settingsChanged = true;
var updateTimetable = true;
var apiClient = new UntisApiClient();
var lessonNumber = 0;
var updateLessonNumber = true;
var timeH = 13;
var timeM = 05;
var dateD = 13;
var dateM = 03;
var dateYe = 2024;

class Untis4GarminView extends WatchUi.View {
    const colorMap = {
        0 => Graphics.COLOR_BLACK,
        1 => Graphics.COLOR_WHITE,
        2 => Graphics.COLOR_RED,
        3 => Graphics.COLOR_GREEN,
        4 => Graphics.COLOR_BLUE,
        5 => Graphics.COLOR_YELLOW,
        6 => Graphics.COLOR_ORANGE,
        7 => Graphics.COLOR_PURPLE,
        8 => Graphics.COLOR_LT_GRAY
    };
    
    var width;
    var height;
    var normalColor;
    var cancelledColor;
    var changedColor;
    var noSubjectColor;
    var dateSystem;
    var dateDelimiter;
    var timeY;
    var dateY;
    var nonLessonInfoY;
    var fontHeightTD;
    var fontTD;
    var subjectY;
    var roomY;
    var classY;
    var fontHeightLesson;
    var fontLesson;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        if (settingsChanged) {
            settingsChanged = false;
            updateTimetable = true;
            loadResources(dc);
        }

        if (updateTimetable) {
            apiClient.getTimetable(dateD, dateM, dateYe);
            updateTimetable = false;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var timeString = Lang.format("$1$:$2$", [timeH, timeM.format("%02d")]);
        var dateString;
        if (dateSystem == 0) {
            dateString = Lang.format("$1$$2$$3$$4$$5$", [dateD, dateDelimiter, dateM, dateDelimiter, dateYe]);
        } else if (dateSystem == 1) {
            dateString = Lang.format("$1$$2$$3$$4$$5$", [dateM, dateDelimiter, dateD, dateDelimiter, dateYe]);
        } else {
            dateString = Lang.format("$1$$2$$3$$4$$5$", [dateYe, dateDelimiter, dateM, dateDelimiter, dateD]);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, timeY, fontTD, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, dateY, fontTD, dateString, Graphics.TEXT_JUSTIFY_CENTER);

        if (apiClient.timetableError) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
            dc.fillRectangle(0, height * 0.2, width, height * 0.6);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, nonLessonInfoY, fontLesson, "Error getting timetable", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        if (apiClient.timetableAvailable) {
            if (apiClient.timetableData.size() == 0) {
                dc.setColor(noSubjectColor, Graphics.COLOR_BLACK);
                dc.fillRectangle(0, height * 0.2, width, height * 0.6);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, nonLessonInfoY, fontLesson, "No lessons", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                var formattedTime = timeH * 100 + timeM;
                var lessonTime = 0;
                if (updateLessonNumber) {
                    lessonNumber = 0;
                    for (var i = 0; i < apiClient.timetableData.size(); i++) {
                        lessonTime = apiClient.timetableData[i]["time"];
                        if (lessonTime > formattedTime) {
                            lessonNumber = i;
                            break;
                        }
                    }
                    if (lessonTime < formattedTime) {
                        lessonNumber = apiClient.timetableData.size();
                    }
                }

                if (lessonNumber >= apiClient.timetableData.size()) {
                    lessonNumber = apiClient.timetableData.size();
                    dc.setColor(noSubjectColor, Graphics.COLOR_BLACK);
                    dc.fillRectangle(0, height * 0.2, width, height * 0.6);
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width / 2, nonLessonInfoY, fontLesson, "No more lessons", Graphics.TEXT_JUSTIFY_CENTER);
                    return;
                }

                if (!updateLessonNumber) {
                    lessonTime = apiClient.timetableData[lessonNumber]["time"];
                }

                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(0, 0, width, height * 0.2);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, timeY, fontTD, lessonTime / 100 + ":" + (lessonTime % 100).format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);

                var numLessons = apiClient.timetableData[lessonNumber]["lessons"].size();
                for (var i = 0; i < numLessons; i++) {
                    var lesson = apiClient.timetableData[lessonNumber]["lessons"][i];
                    var color;
                    if (lesson["state"] == 0) {
                        color = cancelledColor;
                    } else if (lesson["state"] == 1) {
                        color = normalColor;
                    } else {
                        color = changedColor;
                    }
                    dc.setColor(color, Graphics.COLOR_BLACK);
                    dc.fillRectangle((width / numLessons) * i, height * 0.2, width / numLessons, height * 0.6);
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.drawText((width / numLessons) * i + width / (numLessons * 2), subjectY, fontLesson, lesson["subject"], Graphics.TEXT_JUSTIFY_CENTER);
                    dc.drawText((width / numLessons) * i + width / (numLessons * 2), roomY, fontLesson, lesson["room"], Graphics.TEXT_JUSTIFY_CENTER);
                    dc.drawText((width / numLessons) * i + width / (numLessons * 2), classY, fontLesson, lesson["class"], Graphics.TEXT_JUSTIFY_CENTER); 
                }
            }
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, nonLessonInfoY, fontLesson, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function loadResources(dc) {
        var username = Application.Properties.getValue("Username");
        var password = Application.Properties.getValue("Password");
        var untisUrl = Application.Properties.getValue("UntisUrl");
        var schoolName = Application.Properties.getValue("SchoolName"); 

        apiClient.setParameters(untisUrl, username, password, schoolName);

        normalColor = colorMap[Application.Properties.getValue("SubjectNormalColor")];
        cancelledColor = colorMap[Application.Properties.getValue("SubjectCancelledColor")];
        changedColor = colorMap[Application.Properties.getValue("SubjectChangedColor")];
        noSubjectColor = colorMap[Application.Properties.getValue("NoSubjectColor")];
        dateSystem = Application.Properties.getValue("DateSystem");
        dateDelimiter = Application.Properties.getValue("DateDelimiter");

        fontTD = Graphics.FONT_MEDIUM;
        fontHeightTD = dc.getFontHeight(fontTD);
        timeY = (height * 0.2 - fontHeightTD) / 2;
        dateY = (height * 0.2 - fontHeightTD) / 2 + height * 0.8;

        fontLesson = Graphics.FONT_SMALL;
        fontHeightLesson = dc.getFontHeight(fontLesson);
        subjectY = (height * 0.6 - fontHeightLesson) / 2 + height * 0.05;
        roomY = (height * 0.6 - fontHeightLesson) / 2 + height * 0.2;
        classY = (height * 0.6 - fontHeightLesson) / 2 + height * 0.35;
        nonLessonInfoY = (height / 2) - (fontHeightLesson / 2);

        var info = Toybox.Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        timeH = info.hour;
        timeM = info.min;
        dateD = info.day;
        timeM = info.month;
        dateYe = info.year;
    }
}