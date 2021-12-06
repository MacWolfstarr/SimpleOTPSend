<%@ page import="java.util.Random" %>
<%@ page import="java.util.UUID" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String remoteIP=request. getRemoteAddr();

    String action = request.getParameter("action");
    String id = request.getParameter("id");
    String username = request.getParameter("username");
    String mobile = request.getParameter("mobile");
    String district = request.getParameter("district");
    String OTPNumber = request.getParameter("otp");
    System.out.println("::: "+remoteIP+" >>>>>>>>"+action+""+id+""+username+""+mobile+""+district+""+OTPNumber);

    if(action==null||action.equals("")){
        out.print("You are not authorized to access this service");
    }else if (action.equals("sendOTP")) {
        int GeneratedOTP = GenerateOTP();
        String msg = "Your OTP is " + GeneratedOTP;
        String GeneratedUUID = GenerateUUID();
        String msg2 = "Your UUID is " + GeneratedUUID;
        System.out.println(msg);
        System.out.println(msg2);
        SavetoDB(id, username, mobile, district, GeneratedUUID, GeneratedOTP);

        //SendOTP( msg, mobile);
        out.print("Success");

    } else if (action.equals("ValidateOTP")) {
        //check user OTP and user Mobile equals to DB user and OTP and time not more than 2 minutes pass
        ValidateOTP(OTPNumber, mobile);
        out.print("Valid");
    }else{
        out.print("Failed");
    }

%>
<%!
    private static class DBHandler {
        static Connection dbconn;

        public static Connection createDBConnection() {
            try {
                Class.forName("com.mysql.jdbc.Driver");
                dbconn = DriverManager.getConnection("jdbc:mysql://localhost:3306/OTP", "root", "root");
               // dbconn = DriverManager.getConnection("jdbc:mysql://localhost:3306/OTP?user=root&password=7c4KMQ7aiW9dmP6");
                System.out.println("Connected DB successfully");
                return dbconn;
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }
        }
    }


    public static void SavetoDB(String id, String username, String mobile, String district, String generatedUUID, int GeneratedOTP) {
        try {

            Connection conn = DBHandler.createDBConnection();
            int ResultSetAddNewPatient = conn.createStatement().executeUpdate("INSERT INTO OTPList (Id,UserName,Mobile,District,DateTime, UUID, OTP,OTPUsageStatus) VALUES ( '" + id + "','" + username + "','" + mobile + "','" + district + "',CURRENT_TIMESTAMP ,'" + generatedUUID + "','" + GeneratedOTP + "','0' )");
        } catch (Exception e) {
            System.out.print(e);
            e.printStackTrace();
        }
    }

    public static int GenerateOTP() {
        Random r = new Random(System.currentTimeMillis());
        int number = ((1 + r.nextInt(2)) * 10000 + r.nextInt(10000));
        System.out.println(number);
        return number;
    }

    public static String GenerateUUID() {
        UUID uuid = UUID.randomUUID();
        String StringUUID = uuid.toString();

        return StringUUID;
    }

    private void SendOTP(String msg, String mobile) throws Exception {
        String APIUsername = "demo";
        String password = "demo45tw";
        String src = "TWTEST";
        System.out.println(">>>>Request: dst:" + mobile + " - password:" + password + " - src:" + src + " - username:" + APIUsername);
        System.out.println("message:" + msg);
        String encode = null;
        String converted_response = "";

        encode = URLEncoder.encode(msg, "UTF-8");

        String urls = "http://message.textware.lk:5000/sms/send_sms.php?username=" + APIUsername + "&password=" + password + "&src=" + src + "&dst=" + mobile + "&msg=" + encode + "&dr=1";

        StringBuffer response = null;

        URL obj = new URL(urls);
        HttpURLConnection con = (HttpURLConnection) obj.openConnection();

        // optional default is GET
        con.setRequestMethod("GET");

        int responseCode = con.getResponseCode();
        System.out.println("Response Code : " + responseCode);

        BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
        String inputLine;
        response = new StringBuffer();

        while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
        }

        in.close();

        converted_response = response.toString();
        System.out.println("====== ");

    }

    public static String ValidateOTP(String OTPNumber, String mobile) {

        DateTimeFormatter CurrentTime = DateTimeFormatter.ofPattern("HH:mm");
        LocalDateTime now = LocalDateTime.now();
        System.out.println("now"+now);
        now = now.minusSeconds(0);
        String LocalCurrentTime = now.format(CurrentTime);
        int PresentTime = Integer.parseInt(LocalCurrentTime.substring(0, 2)) * 60 + Integer.parseInt(LocalCurrentTime.substring(3, 5));


//        now = now.minusSeconds(300);
//        String SubstractedTime = now.format(CurrentTime);
//        System.out.println("SubstractedTime"+SubstractedTime);
        // System.out.println(SubstractedTime.substring(11, 13));
        //int BeforeFiveMinuteTime = Integer.parseInt(SubstractedTime.substring(0, 2)) * 60 + Integer.parseInt(SubstractedTime.substring(3, 5));

        Connection conn = DBHandler.createDBConnection();
        try {
            ResultSet RsUser = conn.createStatement().executeQuery("select * from OTPList where Mobile ='" + mobile + "' AND OTP ='"+OTPNumber+"' AND OTPUsageStatus = '0'  ");
            if (RsUser.next()) {

                String OTPTime = RsUser.getString("DateTime").substring(11, 16);
                System.out.println(OTPTime);
                int OTPSentTime = Integer.parseInt(RsUser.getString("DateTime").substring(11,13)) * 60 + Integer.parseInt(RsUser.getString("DateTime").substring(14,16));
                System.out.println("ssssssssss"+OTPSentTime);

                if (OTPNumber.equals(RsUser.getString("OTP")) && OTPSentTime <= PresentTime && PresentTime <= OTPSentTime+5) {
                    int RsUser2 = conn.createStatement().executeUpdate("UPDATE OTPList SET OTPUsageStatus ='1', OTPVerfiedTime = CURRENT_TIMESTAMP  WHERE Mobile = '" + mobile + "' AND OTP = '" + OTPNumber + "'");
                    // int RsUser3 = conn.createStatement().executeUpdate("UPDATE OTPList SET OTPVerfiedTime = CURRENT_TIMESTAMP WHERE Mobile = '" + mobile + "' AND OTP = '" + OTPNumber + "' AND OTPUsageStatus = '0' ");
                    System.out.println("Success");
                    return("Success");
                } else {
                    System.out.println("Time Expired");
                    return("Failed");
                }
            } else {
                System.out.println("Failed Verification");
                return("Failed");
            }
        } catch (SQLException ex) {
            ex.printStackTrace();
            return("Failed");
        }
    }
%>
