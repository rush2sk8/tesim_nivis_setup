var HOST = "";

jsolait.baseURI = HOST + "/jsolait/";	
var serviceURL = HOST + "/rpc.cgi";
var jsonrpc = null;
var Version = "1.0.1";
var DEBUG = false;
var methods = [ "config.getVariable", 
				"config.setVariable", 
				"config.getConfig",
				"file.exists", 
				"misc.remoteCmd", 
				"misc.fileDownload",
				"misc.fileUpload",
				"misc.getVersion",
				"misc.getGatewayNetworkInfo",
				"misc.setGatewayNetworkInfo",		
				"misc.getNtpServers",
				"misc.setNtpServers",
				"misc.softwareReset",
				"misc.hardReset",
				"misc.setGprsProviderInfo", 
				"misc.getGprsProviderInfo",
				"user.secure_challenge", 
				"user.secure_login",
				"user.logout" ];
				
function InitJSON(){	
    try {		
        jsonrpc = imprt("jsonrpc");
    } catch (e) {
        alert(e);
    }	
}

function SetPageCommonElements(){
	document.title = "MCS Admin";                     	
	var divHeader = document.getElementById("header");
	if (divHeader){
		divHeader.innerHTML = "<table width='100%' cellspacing='0' cellpadding='0' border='0'>" +
								"<tr>" +
								"<td align='left'><img id='imgCompany' src='images/CompanyLogo.png' height='30px'></td>" +						      
								"<td align='right'>/admin/ User Interface</td>"
								"</tr>" +
							  "</table>";
	}
	
	var divFooter = document.getElementById("footer");
	if (divFooter){    
		divFooter.innerHTML = "<p><table width='100%' 	><tr><td align='left'>Version " + Version + " </td><td align='right'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; NIVIS&reg; 2012</tr></table></p>";
	}
	
    var divMenu = document.getElementById("columnB");    
    if (divMenu != null) {
        divMenu.innerHTML = "<h3>Upgrade</h3>"+
                          "<ul class='list1'>"+
                            "<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='firmware_upgrade.html'>Edge Router Firmware</a></li>"+
                            "<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='load_versa_node_firmware.html'>Transceiver Firmware</a></li>"+
							"<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='upload.html'>Application Website</a></li>"+
                          "</ul>"+
                          "<h3>Configuration</h3>"+
                            "<ul class='list1'>"+
							"<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='application.html'>Log Files</a></li>"+
							"<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='update_profile.html'>Reset Profile</a></li>"+
							"<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='edit_configuration.html'>Advanced Settings</a></li>"+
							"<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='network_configuration.html'>Network</a></li>" +
                          "</ul>"+
                          "<h3>Session</h3>"+
                          "<ul class='list1'>"+
                            "<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='changepassword.html'>Change Password</a></li>"+
                            "<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href='login.html'>Logout</a></li>"+
                          "</ul>"; 
    }
}

function HandleException(ex, msg){
	if (ex.message != null && 
		ex.message.toLowerCase().indexOf("login first") != -1 ||
		ex.message.toLowerCase().indexOf("unable to start session") != -1 ||
		ex.message.toLowerCase().indexOf("internal xml-rpc error") != -1 ||
		ex.message.toLowerCase().indexOf("internal json-rpc error") != -1)		
	{
		top.location.href = "login.html?exp";
		return;
	}
	if(!DEBUG){
		alert(msg);
	}else{
		alert(msg + "\n" + ex);
	}
}

function operationDoneListener(text) {
		ToggleProgressOperation(false);
		innerHTML = "";
		var operationStatus = document.getElementById('operationStatus');
		if ( text ){
			if ( text.result ){
				innerHTML = "Log results:<br><pre>" + text.result + "</pre>";
				DisplayOperationResult("operationStatus", "Operation successfully completed !");
			} else if ( text.error ){
				innerHTML = "Log results:<br><pre>" + text.error + "</pre>";
				DisplayOperationResultError("operationStatus", "Operation failed !");
			}
		}
		document.getElementById("result").innerHTML = innerHTML;				
}

function DisplayOperationResult(controlId, msg) {
    var control = document.getElementById(controlId);
    control.className = "opResultGreen";
    control.innerHTML = msg;
}

function DisplayOperationResultError(controlId, msg) {
    var control = document.getElementById(controlId);
    control.className = "opResultRed";
    control.innerHTML = msg;
}

function ClearOperationResult(controlId) {
    DisplayOperationResult(controlId, "");    
    var control = document.getElementById(controlId);
    control.className = "";
}

function ToggleProgressOperation(bool){
	var operationStatus = document.getElementById("operationStatusImg");
	if(bool){
		operationStatus.style.display = "inline";
	} else{
		operationStatus.style.display = "none";
	}
}