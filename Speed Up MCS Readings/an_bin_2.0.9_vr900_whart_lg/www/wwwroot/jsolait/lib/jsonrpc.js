Module("jsonrpc", "1.0",
	function(mod){
		var urllib = imprt("urllib");
		mod.InvalidServerResponse = Class(mod.Exception,
			function(publ, supr) {
				publ.__init__=function(status){
					supr.__init__.call(this,"The server did not respond with a status 200 (OK) but with: "+status);
					this.status=status;
				};
				publ.status;
			}
		);
		mod.MalformedJSONRpc=Class(mod.Exception,
			function(publ,supr){
				publ.__init__=function(msg,s,trace){
					supr.__init__.call(this,msg,trace);
					this.source=s;
				};
				publ.source;
			}
		);
		mod.JSONRPCError=Class(mod.Exception,function(publ,supr){
				publ.__init__=function(err,trace){
					supr.__init__.call(this,err,trace);
				};
			}
		);
		mod.marshall=function(obj) {
			if(obj==null){
				return "null";
			}else if (typeof(this.JSON)=="object")
			{
				return JSON.stringify(obj) ;
			}else if(obj.toJSON){
				return obj.toJSON();
			}else {
				var v=[];
				for(var attr in obj){
					if(typeof obj[attr]!="function"){
						v.push('"'+attr+'": '+mod.marshall(obj[attr]));
					}
				}
				return "{"+v.join(", ")+"}";
			}
		};
		mod.unmarshall=function(source){
			try{
				var obj;
				if (typeof(JSON)=="object") {
					obj=JSON.parse(source);
				}else
				{
					eval("obj="+source);
				}
				return obj;
			}catch(e){
				throw new mod.MalformedJSONRpc("The server's response could not be parsed.",source,e);
			}
		};
		/*
		mod.RPCMethod=Class(function(publ,supr)
		{
				publ.__init__=function(name,proxy)
				{
					this._name=name;
					this.proxy=proxy;
				};
				publ.__call__=function()
				{
					var args=new Array();
					for(var i=0;i<arguments.length;i++){
						args.push(arguments[i]);
					}
					alert("Type:"+ typeof args[args.length-1]+" Name:"+this._name);
					if(typeof args[args.length-1]=="function" || typeof args[args.length-1]=="object"){
						var callback=args.pop();
						return this.proxy._sendRequest(this._name,args,callback);
					}else{
						return this.proxy._sendNotification(this._name,args);
					}
				};
		});
		*/
		mod.JSONRPCMethod=Class(function(publ) {
			var postData=function(url,user,pass,data,callback){
				if(callback==null){
					var rslt=urllib.postURL(url,user,pass,data,[["Content-Type","text/plain"]]);
					return rslt;
				}else{
					return urllib.postURL(url,user,pass,data,[["Content-Type","text/plain"]],callback);
				}
			};
			var handleResponse=function(resp){
				var status=null;
				try{
					status=resp.status;
				}catch(e){ }
				if(status==200){
					var respTxt="";
					try{
						respTxt=resp.responseText;
					}catch(e){ }
					if(respTxt==null||respTxt==""){
						throw new mod.MalformedJSONRpc("The server responded with an empty document.","");
					}else{
						var rslt=mod.unmarshall(respTxt);
						if(rslt.error!=null){
							throw new mod.JSONRPCError(rslt.error);
						}else{
							return rslt.result;
						}
					}
				}else{
					throw new mod.InvalidServerResponse(status);
				}
			};
			var jsonRequest=function(id,methodName,args){
				var p=[mod.marshall(id),mod.marshall(methodName),mod.marshall(args)];
				return '{"id":'+p[0]+', "method":'+p[1]+', "params":'+p[2]+"}";
			};
			publ.__init__=function(url,methodName,user,pass){
				this.methodName=methodName;
				this.url=url;
				this.user=user;
				this.password=pass;
				this.jsonRequest=jsonRequest;
			};
			publ.__call__=function(){
				var args ;
				if ( arguments.length && typeof(arguments[0])=="object") {
					args = arguments[0] ;
				} else {
					args = new Array();
					for(var i=0;i<arguments.length;i++){
						args.push(arguments[i]);
					}
				}
				if(typeof arguments[arguments.length-1]!='function'){
					var data=jsonRequest("httpReq",this.methodName,args);
					var resp=postData(this.url,this.user,this.password,data);
					return handleResponse(resp);
				}else{
					var cb=args.pop();
					var data=jsonRequest("httpReq",this.methodName,args);
					return postData(this.url,this.user,this.password,data,function(resp)
					{
						var rslt=null;
						var exc=null;
						try{
						rslt=handleResponse(resp);
						}catch(e){
						exc=e;
						}
						try{
						cb(rslt,exc);
						}catch(e){
						}
						args=null;
						resp=null;
					});
				}
			};
			publ.setAuthentication=function(user,pass){
				this.user=user;
				this.password=pass;
			};
			publ.notify=function(){
				var args=new Array();
				for(var i=0;i<arguments.length;i++){
					args.push(arguments[i]);
				}
				var data=jsonRequest(null,this.methodName,args);
				postData(this.url,this.user,this.password,data,function(resp){});
			};
			publ.methodName;
			publ.url;
			publ.user;
			publ.password;
		});
		mod.ServiceProxy=Class(function(publ){
			publ.__init__=function(url,methodNames,user,pass)
			{
				this._url=url;
				this._user=user;
				this._password=pass;
				this._addMethodNames(methodNames);
			};
			publ._addMethodNames=function(methodNames)
			{
				for(var i=0;i<methodNames.length;i++)
				{
					var obj=this;
					var names=methodNames[i].split(".");
					for(var n=0;n<names.length-1;n++)
					{
						var name=names[n];
						if( obj[name] ){
							obj=obj[name];
						}else{
							obj[name]=new Object();
							obj=obj[name];
						}
					}
					var name=names[names.length-1];
					// replaced an if do nothing/else
					if ( !obj[name]){
						var mth=new mod.JSONRPCMethod(this._url,methodNames[i],this._user,this._password);
						obj[name]=mth;
						this._methods.push(mth);
					}
				}
			};
			publ._setAuthentication=function(user,pass){
				this._user=user;
				this._password=pass;
				for(var i=0;i<this._methods.length;i++){
					this._methods[i].setAuthentication(user,pass);
				}
			};
			publ._url;
			publ._user;
			publ._password;
			publ._methods=new Array();
		});
		mod.SimpleHTTPConnection=Class(function(publ,supr){
			publ.__init__=function(url,datahandler){
				this.url=url;
				this.datahandler=datahandler;
			};
			publ.send=function(data){
				urllib.postURL(this.url,data,bind(this,function(req){
						this.processData(req.responseText);
					})
				);
			};
			publ.processData=function(data){
				if(data!=''){
					this.datahandler(data);
				}
			};
		});

		mod.PendingRequest=Class(function(publ,supr){
			publ.__init__=function(callback){
				this.callback=callback;
			};
			publ.handleResponse=function(result,error){
				this.callback.call(null,result,error);
			};
		});
		String.prototype.toJSON=function()
		{
			var s='"'+this.replace(/(["\\])/g,'\\$1')+'"';
			s=s.replace(/(\n)/g,"\\n");
			return s;
		};
		Number.prototype.toJSON=function()
		{
			return this.toString();
		};
		Boolean.prototype.toJSON=function()
		{
			return this.toString();
		};
		Date.prototype.toJSON=function()
		{
			var padd=function(s,p){
				s=p+s;
				return s.substring(s.length-p.length);
			};
			var y=padd(this.getUTCFullYear(),"0000");
			var m=padd(this.getUTCMonth()+1,"00");
			var d=padd(this.getUTCDate(),"00");
			var h=padd(this.getUTCHours(),"00");
			var min=padd(this.getUTCMinutes(),"00");
			var s=padd(this.getUTCSeconds(),"00");
			var isodate=y+m+d+"T"+h+":"+min+":"+s;
			return '{"jsonclass":["sys.ISODate", ["'+isodate+'"]]}';
		};
		Array.prototype.toJSON=function(){
			var v=[];
			for(var i=0;i<this.length;i++){
				v.push(mod.marshall(this[i]));
			}
				return "["+v.join(", ")+"]";
		};
		mod.__main__=function()
		{
		};
	}
);
