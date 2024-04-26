import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

class UntisApiClient {
    var url = "";
    var username = "";
    var password = "";
    var sessionID = "";
    var personID = 0;
    var personType = 0;
    var myTimer = new Timer.Timer();
    var timetableDate = 0;
    public var timetableData = [];
    public var timetableAvailable = false;
    public var timetableError = false;

    const specialCharacterToUrl = {
        "ä" => "%C3%A4",
        "ö" => "%C3%B6",
        "ü" => "%C3%BC",
        "Ä" => "%C3%84",
        "Ö" => "%C3%96",
        "Ü" => "%C3%9C",
        "ß" => "%C3%9F"
    };

    /* 
        lessonData = [
            {
                "time" => 745,
                "lessons" => [
                    {
                        "subject" => "Math",
                        "room" => "215",
                        "class" => "10A",
                        "state" => 1 // 0 = cancelled, 1 = normal, 2 = changed
                        "id" => 1234,
                        "origroom" = -1 // -1 = no room change, Any other value = original room
                    },
                    {
                        "subject" => "English",
                        "room" => "213",
                        "class" => "10A",
                        "state" => 0
                        "id" => 1235,
                        "origroom" = 122
                    }
                ]
            },
            {
                "time" => 835,
                "lessons" => [
                    {
                        "subject" => "Art",
                        "room" => "3",
                        "class" => "10A",
                        "state" => 1
                        "id" => 1236,
                        "origroom" = -1
                    }
                ]
            }
        ]
    */

    public function initialize() {
    }

    public function setParameters(url as String, username as String, password as String, schoolName as String) {
        self.url = "https://" + url + "/WebUntis/jsonrpc.do?school=" + schoolName;
        for (var i = 0; i < specialCharacterToUrl.size(); i++) {
            self.url = self.stringReplace(self.url, self.specialCharacterToUrl.keys()[i], self.specialCharacterToUrl.values()[i]);
        }
        self.username = username;
        self.password = password;
    }

    public function getTimetable(day as Number, month as Number, year as Number) as Void {
        self.timetableDate = year * 10000 + month * 100 + day;
        self.timetableAvailable = false;
        self.timetableError = false;
        self.authenticate();
    }

    function authCallback(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            if (data.hasKey("error")) {
                self.timetableError = true;
                WatchUi.requestUpdate();
            } else {
                self.sessionID = data["result"]["sessionId"];
                self.personID = data["result"]["personId"];
                self.personType = data["result"]["personType"];
                self.requestTimetable();
            }
        } else {
            self.timetableError = true;
            WatchUi.requestUpdate();
        }
    }

    function authenticate() {
        var request = {
            "id" => 1,
            "method" => "authenticate",
            "params" => {
                "user" => self.username,
                "password" => self.password,
                "client" => "Untis4Garmin"
            },
            "jsonrpc" => "2.0"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(self.url, request, options, method(:authCallback));
    }

    function logoutCallback(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            if (data.hasKey("error")) {
                self.timetableError = true;
            } else {
                self.timetableAvailable = true;
            }
        } else {
            self.timetableError = true;
        }
        WatchUi.requestUpdate();
    }

    function logout() {
        var request = {
            "id" => 1,
            "method" => "logout",
            "params" => {},
            "jsonrpc" => "2.0"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Cookie" => "JSESSIONID=" + self.sessionID
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(self.url, request, options, method(:logoutCallback));
    }

    function requestTimetableCallback(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            if (data.hasKey("error")) {
                self.timetableError = true;
                WatchUi.requestUpdate();
            } else {
                var result = data["result"];
                
                var lessons = [];
                for (var i = 0; i < result.size(); i++) {
                    var lesson = {
                        "time" => result[i]["startTime"],
                        "lessons" => []
                    };

                    var found = false;
                    for (var j = 0; j < lessons.size(); j++) {
                        if (lessons[j]["time"] == lesson["time"]) {
                            found = true;
                            break;
                        }
                    }
                    if (found) {
                        continue;
                    }
                    
                    for (var j = 0; j < result.size(); j++) {
                        if (result[i]["startTime"] == result[j]["startTime"]) {
                            var subject = result[j]["su"][0]["name"];
                            var room = result[j]["ro"][0]["name"];
                            var klasse = "";
                            for (var x = 0; x < result[j]["kl"].size(); x++) {
                                if (x > 0) {
                                    klasse += ", ";
                                }
                                klasse += result[j]["kl"][x]["name"];
                            }
                            var state;
                            if (result[j].hasKey("code") && result[j]["code"].equals("cancelled")) {
                                state = 0;
                            } else if (result[j].hasKey("code") && result[j]["code"].equals("irregular")) {
                                state = 2;
                            } else {
                                state = 1;
                            }

                            var origroom = -1;
                            if (result[j]["ro"][0].hasKey("orgname")) {
                                origroom = result[j]["ro"][0]["orgname"];
                            }

                            var lessonData = {
                                "subject" => subject,
                                "room" => room,
                                "class" => klasse,
                                "state" => state,
                                "id" => result[j]["su"][0]["id"],
                                "origroom" => origroom
                            };

                            if (state == 0) {   // Might be wrong in some cases, still investigating how the api handles this
                                for (var k = 0; k < lessons.size(); k++) {
                                    for (var l = 0; l < lessons[k]["lessons"].size(); l++) {
                                        if (lessons[k]["lessons"][l]["id"] == lessonData["id"]) {
                                            if (lessons[k]["lessons"][l]["state"] == 1) {
                                                lessons[k]["lessons"][l]["state"] = 2;
                                            }                                            
                                        }
                                    }
                                }
                            }

                            lesson["lessons"].add(lessonData);
                        }
                    }
                    lessons.add(lesson);
                }
                for (var i = 0; i < lessons.size(); i++) {
                    for (var j = i + 1; j < lessons.size(); j++) {
                        if (lessons[i]["time"] > lessons[j]["time"]) {
                            var temp = lessons[i];
                            lessons[i] = lessons[j];
                            lessons[j] = temp;
                        }
                    }
                }

                self.timetableData = lessons;
                self.logout();
            }
        } else {
            self.timetableError = true;
            WatchUi.requestUpdate();
        }
    }

    function requestTimetable() {
        var request = {
            "id" => 1,
            "method" => "getTimetable",
            "params" => {
                "options" => {
                    "element" => {
                        "id" => self.personID,
                        "type" => self.personType
                    },
                    "klasseFields" => [
                        "id",
                        "name",
                        "longname",
                        "externalkey"
                    ],
                    "roomFields" => [
                        "id",
                        "name",
                        "longname",
                        "externalkey"
                    ],
                    "subjectFields" => [
                        "id",
                        "name",
                        "longname",
                        "externalkey"
                    ],
                    "startDate" => timetableDate,
                    "endDate" => timetableDate
                },
            },
            "jsonrpc" => "2.0"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Cookie" => "JSESSIONID=" + self.sessionID
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(self.url, request, options, method(:requestTimetableCallback));
    }

    function stringReplace(string as String, search, replace) as String {
        var result = "";
        for (var i = 0; i < string.length(); i++) {
            if (string.substring(i, i + 1).equals(search)) {
                result += replace;
            } else {
                result += string.substring(i, i + 1);
            }
        }
        return result;
    }
}