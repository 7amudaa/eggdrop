# -----------------------------------
# IP/DOMAIN API info from ip-api.com
# -----------------------------------

 bind pub - !ip ipapiproc
 bind pub - !host ipapiproc
 bind pub - !ipapi ipapiproc
 bind pub - !ipinfo ipapiproc

 package require http
 package require tls
 package require json

proc ipapiproc {nick host hand chan text} {
 ::http::register https 443 [list ::tls::socket -autoservername true]
 if {![llength [split $text]]} {
 putserv "NOTICE $nick :Use: !ip 127.0.0.1 or !ip mydomain.com"
 return 0
 }
 # JSON regexp API call
 set url "http://ip-api.com/json/$text" 
 set token [::http::geturl $url -timeout 10000]
 set page [::http::data $token]
 upvar 0 $token state
 if {$state(status) ne "ok"} {
 putserv "PRIVMSG $chan :\00303IP-API:\003 $state(url) made $state(status) error"
 return 0
 }
 ::http::cleanup $token
 ::http::unregister https

 # $page is the result of your geturl
 # Page=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,asn,query,continent,continentCode,currency,asname,mobile,proxy,hosting
 set data [json::json2dict $page]
 set ip [string map {" " ":"} [dict get $data query]]
 set isp [dict get $data isp]
 set country [dict get $data country]
 set countryCode [dict get $data countryCode]
 set org [dict get $data org]
 set city [dict get $data city]
 set zip [dict get $data zip]
 set regionName [dict get $data regionName]
 set lat [dict get $data lat]
 set lon [dict get $data lon]
 # Works only on HTTPS (paid service)
 #if { [dict get $data mobile] eq "true"} { set mobile avaible } else  { set mobile n/a }
 #if { [dict get $data proxy] eq "true"} { set proxy avaible } else  { set proxy n/a }
 #if { [dict get $data hosting] eq "true"} { set hosting avaible } else  { set hosting n/a }

 # Announce data to $chan
 if {[dict get $data status] eq "fail"} {
 set status [dict get $data message]
 putserv "PRIVMSG $chan :\00303IP-API:\003 $message ($ip). Used correct IP/Domain?"
 return  0
 }
 if {[info exists country]} {
 putserv "PRIVMSG $chan :\00303IP-API:\003 $ip - \00303ISP:\003 $isp \00303ORG:\003 $org \00303COUNTRY:\003 $countryCode, $country"
 }
 if {[info exists lat]} {
 putserv "PRIVMSG $chan :\00303IP-API:\003 \00303CITY:\003 $city \00303ZIP:\003 $zip\00303 REGION:\003 $regionName ($lat,$lon)"
 }
 if {[info exists mobile]} {
 putserv "PRIVMSG $chan :\00303IP-API:\003 \00303HOSTING:\003 $hosting \00303PROXY:\003 $proxy \00303MOBILE:\003 $mobile"
 }
 else {
 putserv "PRIVMSG $chan :\00303IP-API:\003 No data found. Used correct IP/Domain?"
 }
}

  putlog "\[SCRiPT\] IP-API Info :: Loaded successfully."

  
