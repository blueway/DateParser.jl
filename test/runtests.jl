using DateParser
using Base.Test

using TimeZones

timezone = TimeZone("Europe/Warsaw")
default_d = Date(1976, 7, 4)
default_dt = DateTime(default_d)
default_zdt = ZonedDateTime(default_dt, timezone)
timezone_infos = Dict{AbstractString, TimeZone}(
    "TEST" => FixedTimeZone("TEST", 3600),
    "UTC" => FixedTimeZone("UTC", 0),
    "GMT" => FixedTimeZone("GMT", 0),
    "Etc/GMT+3" => FixedTimeZone("GMT+3", -10800),
)

# Weird things
@test parse(ZonedDateTime, "1999 2:30 America / Winnipeg", default=default_zdt).timezone.name == Symbol("America/Winnipeg")
@test parse(ZonedDateTime, "1999 2:30 MST 7 MDT", default=default_zdt).timezone.name == Symbol("MST7MDT")

# Unsupported formats
@test isnull(tryparse(ZonedDateTime, "1999 2:30 (FOO) +1:00", default=default_zdt))
@test isnull(tryparse(ZonedDateTime, "1999 2:30 +1:00 FOO", default=default_zdt))
# MMYYYY is not supported because it will parse as 3 date tokens
@test parse(Date, "102015", default=default_d) == Date(2015, 10, 20)

# tryparse
@test get(tryparse(ZonedDateTime, "Oct 13, 1994 12:10:14 UTC", default=default_zdt, timezone_infos=timezone_infos)) == ZonedDateTime(DateTime(1994, 10, 13, 12, 10, 14), FixedTimeZone("UTC", 0))
@test isnull(tryparse(ZonedDateTime, "garbage", default=default_zdt))
@test get(tryparse(DateTime, "Oct 13, 1994 12:10:14 UTC", default=default_dt)) == DateTime(1994, 10, 13, 12, 10, 14)
@test isnull(tryparse(DateTime, "garbage", default=default_dt))
@test get(tryparse(Date, "Oct 13, 1994 12:10:14 UTC", default=default_d)) == Date(1994, 10, 13)
@test isnull(tryparse(Date, "garbage", default=default_d))

# tokenize
@test DateParser.tokenize("⁇.éAû2") == ["⁇.", "éAû", "2"]
@test DateParser.tokenize("1999 Feb 3 12:20:30.5") == ["1999", "Feb", "3", "12", ":", "20", ":", "30", ".", "5"]
@test DateParser.tokenize("GMT+3") == ["GMT", "+", "3"]  # Note: ispunct('+') is false

# convertyear
@test DateParser.convertyear(10) == 2010
@test DateParser.convertyear(95) == 1995
@test DateParser.convertyear(49) == 2049
@test DateParser.convertyear(50) == 1950
@test DateParser.convertyear(10, 2075) == 2110

# converthour
@test DateParser.converthour(1, :am) == 1
@test DateParser.converthour(1, :pm) == 13
@test DateParser.converthour(12, :am) == 0
@test DateParser.converthour(12, :pm) == 12

# _tryparse {TimeZone}
@test get(DateParser._tryparse(TimeZone, "Etc/GMT+3", translation=timezone_infos)).name == Symbol("GMT+3")
@test get(DateParser._tryparse(TimeZone, "America/Winnipeg")).name == Symbol("America/Winnipeg")
@test get(DateParser._tryparse(TimeZone, "MST7MDT")).name == Symbol("MST7MDT")
@test get(DateParser._tryparse(TimeZone, "Asia/Ho_Chi_Minh")).name == Symbol("Asia/Ho_Chi_Minh")
@test get(DateParser._tryparse(TimeZone, "America/North_Dakota/New_Salem")).name == Symbol("America/North_Dakota/New_Salem")
@test get(DateParser._tryparse(TimeZone, "America/Port-au-Prince")).name == Symbol("America/Port-au-Prince")
@test get(DateParser._tryparse(TimeZone, "z")).name == Symbol("UTC")
@test isnull(DateParser._tryparse(TimeZone, "badzone"))

# _tryparse {Month}
@test get(DateParser._tryparse(Dates.Month, "january")).value == 1
@test get(DateParser._tryparse(Dates.Month, "oct")).value == 10
@test isnull(DateParser._tryparse(Dates.Month, "garbage"))

# _tryparse {DayOfWeek}
@test get(DateParser._tryparse(DateParser.DayOfWeek, "monday")).value == 1
@test get(DateParser._tryparse(DateParser.DayOfWeek, "wed")).value == 3
@test isnull(DateParser._tryparse(DateParser.DayOfWeek, "garbage"))

# parsefractional
@test DateParser.parsefractional("5") == 0.5
@test DateParser.parsefractional("50") == 0.5
@test DateParser.parsefractional("999") == 0.999

# All code paths
@test parse(ZonedDateTime, "", default=default_zdt) == default_zdt
@test parse(DateTime, "", default=default_dt) == default_dt
@test parse(Date, "", default=default_d) == default_d
@test parse(DateTime, "19990203T2359", default=default_dt) == DateTime(1999, 2, 3, 23, 59)
@test parse(DateTime, "990203", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "990203T235945.54", default=default_dt) == DateTime(1999, 2, 3, 23, 59, 45, 540)
@test parse(DateTime, "19990203", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "19990203235945", default=default_dt) == DateTime(1999, 2, 3, 23, 59, 45)
@test parse(DateTime, "12h30", default=default_dt) == DateTime(1976, 7, 4, 12, 30)
@test parse(DateTime, "12h30s", default=default_dt) == DateTime(1976, 7, 4, 12, 0, 30)
@test parse(DateTime, "12m30", default=default_dt) == DateTime(1976, 7, 4, 0, 12, 30)
@test parse(DateTime, "30s5m12h", default=default_dt) == DateTime(1976, 7, 4, 12, 5, 30)
@test parse(DateTime, "12.5h", default=default_dt) == DateTime(1976, 7, 4, 12, 30)
@test parse(DateTime, "12.5m", default=default_dt) == DateTime(1976, 7, 4, 0, 12, 30)
@test parse(DateTime, "12.5s", default=default_dt) == DateTime(1976, 7, 4, 0, 0, 12, 500)
@test parse(DateTime, "12:20.5", default=default_dt) == DateTime(1976, 7, 4, 12, 20, 30)
@test parse(DateTime, "12:20:30.5", default=default_dt) == DateTime(1976, 7, 4, 12, 20, 30, 500)
@test parse(DateTime, "2.3.99", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "2.3.1999", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "3.FEB.99", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "2/3/1999", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "1999/FEB/3", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "1999/3/FEB", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "12 am", default=default_dt) == DateTime(1976, 7, 4, 0)
@test parse(DateTime, "1 pm", default=default_dt) == DateTime(1976, 7, 4, 13)
@test parse(DateTime, "12am", default=default_dt) == DateTime(1976, 7, 4, 0)
@test parse(DateTime, "1pm", default=default_dt) == DateTime(1976, 7, 4, 13)
@test parse(DateTime, "99 02 03", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "99FEB03", default=default_dt) == DateTime(1999, 2, 3)
@test isnull(tryparse(DateTime, "99! Year FEB 03 Day", default=default_dt))
@test parse(DateTime, "99! Year FEB 03 Day", fuzzy=true, default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "Thursday october the 13 1994", default=default_dt) == DateTime(1994, 10, 13)
@test parse(DateTime, "February-03-1999", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "February of 1999", default=default_dt) == DateTime(1999, 2, 4)
@test parse(DateTime, "12h am", default=default_dt) == DateTime(1976, 7, 4, 0)
@test parse(DateTime, "1h pm", default=default_dt) == DateTime(1976, 7, 4, 13)
@test parse(ZonedDateTime, "13h Etc/GMT+3", default=default_zdt, timezone_infos=timezone_infos).timezone.offset.utc == Dates.Second(-10800)
@test parse(ZonedDateTime, "13h +03:00", default=default_zdt).timezone.offset.utc == Dates.Second(10800)
@test parse(ZonedDateTime, "13h -0300", default=default_zdt).timezone.offset.utc == Dates.Second(-10800)
@test parse(ZonedDateTime, "13h +03", default=default_zdt).timezone.offset.utc == Dates.Second(10800)
@test parse(ZonedDateTime, "13h -3", default=default_zdt).timezone.offset.utc == Dates.Second(-10800)
@test parse(ZonedDateTime, "13h -0 (GMT)", default=default_zdt, timezone_infos=timezone_infos).timezone.offset.utc == Dates.Second(0)
@test isnull(tryparse(ZonedDateTime, "13h +12345", default=default_zdt))
@test isnull(tryparse(ZonedDateTime, "13h +", default=default_zdt))
@test parse(DateTime, "february the 3rd 1999", default=default_dt) == DateTime(1999, 2, 3)
@test isnull(tryparse(DateTime, "hi it's 99 february the 3rd", default=default_dt))
@test parse(DateTime, "hi it's 99 february the 3rd", fuzzy=true, default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "1, 2, 3, 4", default=default_dt) == DateTime(2003, 1, 2, 4)
@test parse(DateTime, "1999 04 05 13 59 59 99") == DateTime(1999, 04, 05, 13, 59, 59, 99)
@test isnull(tryparse(DateTime, "1999 04 05 13 59 59 99 92"))
@test parse(DateTime, "1999 04 05 13 59 59 999") == DateTime(1999, 04, 05, 13, 59, 59, 999)
@test parse(DateTime, "1999 04 05 1359") == DateTime(1999, 04, 05, 13, 59)
@test parse(DateTime, "19990405 135959") == DateTime(1999, 04, 05, 13, 59, 59)
@test isnull(tryparse(DateTime, "19990405 1359599"))
@test isnull(tryparse(DateTime, "1999 04 05 13595999"))
@test parse(DateTime, "1999 04 05 135959999") == DateTime(1999, 04, 05, 13, 59, 59, 999)
@test parse(DateTime, "19990405 135959999") == DateTime(1999, 04, 05, 13, 59, 59, 999)
@test parse(DateTime, "feb 3", default=default_dt) == DateTime(1976, 2, 3)
@test parse(DateTime, "feb 1999", default=default_dt) == DateTime(1999, 2, 4)
@test parse(DateTime, "1999", default=default_dt) == DateTime(1999, 7, 4)
@test parse(DateTime, "99-02", default=default_dt) == DateTime(1999, 2, 4)
@test parse(DateTime, "02-99", default=default_dt) == DateTime(1999, 2, 4)
@test parse(DateTime, "02-03", default=default_dt) == DateTime(1976, 2, 3)
@test parse(DateTime, "03-02", dayfirst=true, default=default_dt) == DateTime(1976, 2, 3)
@test parse(DateTime, "FEB 03 99", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "99 FEB 03", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "03 FEB 04", default=default_dt) == DateTime(2004, 2, 3)
@test parse(DateTime, "04 FEB 03", yearfirst=true, default=default_dt) == DateTime(2004, 2, 3)
@test parse(DateTime, "03 99 FEB", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "04 03 FEB", default=default_dt) == DateTime(2004, 2, 3)
@test parse(DateTime, "99 02 03", default=default_dt) == DateTime(1999, 2, 3)
@test parse(DateTime, "04 02 03", yearfirst=true, default=default_dt) == DateTime(2004, 2, 3)
@test parse(DateTime, "13 02 04", default=default_dt) == DateTime(2004, 2, 13)
@test parse(DateTime, "03 02 04", dayfirst=true, default=default_dt) == DateTime(2004, 2, 3)
@test parse(DateTime, "02 03 04", default=default_dt) == DateTime(2004, 2, 3)
@test parse(DateTime, "2:30", default=default_dt) == DateTime(1976, 7, 4, 2, 30)
@test parse(DateTime, "1999 2:30", default=default_dt) == DateTime(1999, 7, 4, 2, 30)
@test parse(DateTime, "99 2:30", default=default_dt) == DateTime(1999, 7, 4, 2, 30)
@test parse(DateTime, "22 2:30", default=default_dt) == DateTime(1976, 7, 22, 2, 30)
@test parse(DateTime, "1994/10/13", default=default_dt) == DateTime(1994, 10, 13, 0, 0, 0)
@test parse(DateTime, "13h", default=default_dt) == DateTime(1976, 7, 4, 13, 0, 0, 0)
@test parse(DateTime, "13m", default=default_dt) == DateTime(1976, 7, 4, 0, 13, 0, 0)
@test parse(DateTime, "13s", default=default_dt) == DateTime(1976, 7, 4, 0, 0, 13, 0)
@test parse(DateTime, "0.5s", default=default_dt) == DateTime(1976, 7, 4, 0, 0, 0, 500)
@test parse(ZonedDateTime, "1999", default=default_zdt).timezone == default_zdt.timezone
@test parse(ZonedDateTime, "1999 2:30 TEST", timezone_infos=timezone_infos, default=default_zdt).timezone == timezone_infos["TEST"]
@test parse(ZonedDateTime, "1999 2:30 WET", default=default_zdt).timezone.name == :WET
@test parse(ZonedDateTime, "1999 2:30 Z", default=default_zdt).timezone == FixedTimeZone("UTC", 0)
@test isnull(tryparse(ZonedDateTime, "1999 2:30 FAIL", default=default_zdt))
@test parse(ZonedDateTime, "1999 2:30 +01:00", default=default_zdt).timezone.name == :local
@test parse(ZonedDateTime, "1999 2:30 +01:00", default=default_zdt).timezone.offset.utc == Dates.Second(3600)
@test parse(ZonedDateTime, "1999 2:30 -01:00 (TEST)", timezone_infos=timezone_infos, default=default_zdt).timezone.name == :TEST
# If both a timezone in timezone_infos and a timezone offset exist use the timezone in timezone_infos
@test parse(ZonedDateTime, "1999 2:30 -01:00 (TEST)", timezone_infos=timezone_infos, default=default_zdt).timezone.offset.utc == Dates.Second(3600)

@test parse(ZonedDateTime, "1999 2:30 America/Winnipeg", default=default_zdt).timezone.name == Symbol("America/Winnipeg")
@test parse(ZonedDateTime, "1999 2:30 MST7MDT", default=default_zdt).timezone.name == Symbol("MST7MDT")
@test parse(ZonedDateTime, "1999 2:30 Asia/Ho_Chi_Minh", default=default_zdt).timezone.name == Symbol("Asia/Ho_Chi_Minh")
@test parse(ZonedDateTime, "1999 2:30 America/North_Dakota/New_Salem", default=default_zdt).timezone.name == Symbol("America/North_Dakota/New_Salem")
@test parse(ZonedDateTime, "1999 2:30 America/Port-au-Prince", default=default_zdt).timezone.name == Symbol("America/Port-au-Prince")

@test parse(ZonedDateTime, "1999 2:30 (America/Winnipeg)", default=default_zdt).timezone.name == Symbol("America/Winnipeg")
@test isnull(tryparse(ZonedDateTime, "1999 2:30 (BAD-)", default=default_zdt))
@test parse(ZonedDateTime, "1999 2:30 (BAD-)", fuzzy=true, default=default_zdt).timezone.name == Symbol("Europe/Warsaw")

@test parse(DateTime, "21:38, 30 May 2006 (UTC)", default=default_dt) == DateTime(2006, 5, 30, 21, 38)

@test parse(DateTime, "2015.10.02 10:21:59.45", default=default_dt) == DateTime(2015, 10, 2, 10, 21, 59, 450)

@test parse(Date, "301213", yearfirst=true, default=default_d) == Date(2030, 12, 13)
@test parse(Date, "301213", dayfirst=true, default=default_d) == Date(2013, 12, 30)

@test isnull(tryparse(DateTime, "1999-10-13 pm", default=default_dt))

temp = parse(ZonedDateTime, "1999 2:30 (UTC+1:00)", default=default_zdt)
@test temp.timezone.name == Symbol("UTC+1:00")
@test temp.timezone.offset.utc == Dates.Second(3600)
temp = parse(ZonedDateTime, "1999 2:30 +1:00 (FOO)", default=default_zdt)
@test temp.timezone.name == Symbol("FOO")
@test temp.timezone.offset.utc == Dates.Second(3600)

temp = parse(ZonedDateTime, "19991212 0259+1:00")
@test temp.timezone.offset.utc == Dates.Second(3600)
@test TimeZones.localtime(temp) == DateTime(1999, 12, 12, 2, 59)

@test isnull(tryparse(Date, "1/b/c", default=default_d))
@test isnull(tryparse(Date, "1/b/3", default=default_d))

# Out of range
@test isnull(tryparse(ZonedDateTime, "1999 2:30 +25:00", default=default_zdt))
@test isnull(tryparse(ZonedDateTime, "1999 2:30 +00:62", default=default_zdt))

# locale
DateParser.DAYOFWEEKTOVALUE["french"] = Dict("lundi" => 1, "mardi" => 2,
    "mercredi" => 3, "jeudi" => 4, "vendredi" => 5, "samedi" => 6, "dimanche" => 7)
DateParser.DAYOFWEEKABBRTOVALUE["french"] = Dict("lun" => 1, "mar" => 2,
    "mer" => 3, "jeu" => 4, "ven" => 5, "sam" => 6, "dim" => 7)
DateParser.MONTHTOVALUE["french"] = Dict("janvier" => 1, "février" => 2,
    "mars" => 3, "avril" => 4, "mai" => 5, "juin" => 6, "juillet" => 7, "août" => 8,
    "septembre" => 9, "octobre" => 10, "novembre" => 11, "décembre" => 12)
DateParser.MONTHABBRTOVALUE["french"] = Dict("janv" => 1, "févr" => 2,
    "mars" => 3, "avril" => 4, "mai" => 5, "juin" => 6, "juil" => 7, "août" => 8,
    "sept" => 9, "oct" => 10, "nov" => 11, "déc" => 12)
DateParser.HMS["french"] = DateParser.HMS["english"]
DateParser.AMPM["french"] = DateParser.AMPM["english"]

@test parse(DateTime, "28 mai 2014", locale="french", default=default_dt) == DateTime(2014, 5, 28)
@test parse(DateTime, "28 févr 2014", locale="french", default=default_dt) == DateTime(2014, 2, 28)
@test parse(DateTime, "jeu 28 août 2014", locale="french", default=default_dt) == DateTime(2014, 8, 28)
@test parse(DateTime, "lundi 28 avril 2014", locale="french", default=default_dt) == DateTime(2014, 4, 28)
@test parse(DateTime, "28 févr 2014", locale="french", default=default_dt) == DateTime(2014, 2, 28)
@test parse(DateTime, "12 am", locale="french", default=default_dt) == DateTime(1976, 7, 4, 0)
@test parse(DateTime, "1 pm", locale="french", default=default_dt) == DateTime(1976, 7, 4, 13)

# Examples I found in Python's dateutil's pointers links
date = ZonedDateTime(DateTime(1995, 2, 4), timezone)
@test parse(ZonedDateTime, "1995-02-04", default=default_zdt) == date
@test parse(ZonedDateTime, "2/4/95", default=default_zdt) == date
@test parse(ZonedDateTime, "4/2/95", default=default_zdt, dayfirst=true) == date
@test parse(ZonedDateTime, "95/2/4", default=default_zdt) == date
@test parse(ZonedDateTime, "4.2.1995", default=default_zdt, dayfirst=true) == date
@test parse(ZonedDateTime, "04-FEB-1995", default=default_zdt) == date
@test parse(ZonedDateTime, "4-February-1995", default=default_zdt) == date
@test parse(ZonedDateTime, "19950204", default=default_zdt) == date
@test parse(ZonedDateTime, "1995FEB04", default=default_zdt) == date

@test parse(DateTime, "1995-02", default=default_dt) == DateTime(1995, 2, 4)
@test parse(DateTime, "1995", default=default_dt) == DateTime(1995, 7, 4)

@test parse(DateTime, "1997", default=default_dt) == DateTime(1997, 7, 4)
@test parse(DateTime, "1997-07", default=default_dt) == DateTime(1997, 7, 4)
@test parse(DateTime, "1997-07-16", default=default_dt) == DateTime(1997, 7, 16)
@test parse(DateTime, "1997-07-16T19:20+01:00", default=default_dt) == DateTime(1997, 7, 16, 19, 20)
@test parse(DateTime, "1997-07-16T19:20:30+01:00", default=default_dt) == DateTime(1997, 7, 16, 19, 20, 30)
@test parse(DateTime, "1997-07-16T19:20:30.45+01:00", default=default_dt) == DateTime(1997, 7, 16, 19, 20, 30, 450)

date = DateTime(1976, 7, 4)
@test parse(DateTime, "July 4, 1976", default=default_dt) == date
@test parse(DateTime, "7 4 1976", default=default_dt) == date
@test parse(DateTime, "4 jul 1976", default=default_dt) == date
@test parse(DateTime, "7-4-76", default=default_dt) == date
@test parse(DateTime, "19760704", default=default_dt) == date

@test parse(DateTime, "0:01:02", default=default_dt) == DateTime(1976, 7, 4, 0, 1, 2)
@test isnull(tryparse(DateTime, "0 1 2", default=default_dt))  # month of 0 not valid
@test parse(DateTime, "12h 59.00s am", default=default_dt) == DateTime(1976, 7, 4, 0, 0, 59)
@test parse(DateTime, "59s", default=default_dt) == DateTime(1976, 7, 4, 0, 0, 59)
@test parse(DateTime, "1 m 2s", default=default_dt) == DateTime(1976, 7, 4, 0, 1, 2)

@test parse(DateTime, "0:01:02 on July 4, 1976", default=default_dt) == DateTime(1976, 7, 4, 0, 1, 2)
@test parse(DateTime, "1976-07-04T00:01:02Z", default=default_dt) == DateTime(1976, 7, 4, 0, 1, 2)
@test parse(DateTime, "July 4, 1976 12:01:02 am", default=default_dt) == DateTime(1976, 7, 4, 0, 1, 2)

@test parse(DateTime, "23:59:59", default=default_dt) == DateTime(1976, 7, 4, 23, 59, 59)
@test parse(DateTime, "23:59", default=default_dt) == DateTime(1976, 7, 4, 23, 59)
@test parse(DateTime, "2359", default=default_dt) == DateTime(2359,7, 4)
@test parse(DateTime, "23", default=default_dt) == DateTime(1976, 7, 23)
@test parse(DateTime, "23:59:59.9942", default=default_dt) == DateTime(1976, 7, 4, 23, 59, 59, 994)
@test parse(DateTime, "1995-02-05 00:00", default=default_dt) == DateTime(1995, 2, 5)
@test parse(DateTime, "19951231T235959", default=default_dt) == DateTime(1995, 12, 31, 23, 59, 59)

@test parse(DateTime, "1995-02-04 22:45:00", default=default_dt) == DateTime(1995, 2, 4, 22, 45)

@test parse(DateTime, "23:59:59Z", default=default_dt) == DateTime(1976, 7, 4, 23, 59, 59)
@test parse(DateTime, "12:00Z", default=default_dt) == DateTime(1976, 7, 4, 12)
@test parse(DateTime, "13:00+01:00", default=default_dt) == DateTime(1976, 7, 4, 13)
