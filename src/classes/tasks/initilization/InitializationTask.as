package classes.tasks.initilization
{
	import com.adobe.crypto.AgeCrypt;
	import com.thread.SimpleTask;
	
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.events.AMFErrorEvent;
	import classes.api.events.BrowseProjectEvent;
	import classes.api.events.GetProjectInfoEvent;
	import classes.api.events.OrderUserListEvent;
	import classes.api.events.UserEvent;
	import classes.api.social.vk.VKApi;
	import classes.api.social.vk.events.IFlashEvent;
	
	public class InitializationTask extends SimpleTask
	{
		public static const INITIALIZING_VK_API : int = 5;
		public static const CHECKING_RUNNING_APPLICATION_COPY : int = 10;
		public static const GETTING_APP_USERS   : int = 15;
		public static const GETTING_USER_INFO   : int = 20;
		public static const LOADING_SETTINGS    : int = 30;
		public static const CONNECTING          : int = 40;
		public static const REGISTERING         : int = 50;
		public static const ORDERING_APP_USERS  : int = 60;
		public static const BROWSING_EXAMPLES   : int = 70;
		public static const LOAD_PROJECT_INFO_IF_NEEDED : int = 80;
		public static const DONE                : int = 90;
		
		private var api : MainAPIImplementation;
		private var loader : URLLoader;
		
		private var stage : Stage;
		private var params : Object;
		
		public function InitializationTask( stage : Stage )
		{
			super();
			this.stage = stage;
		}
		
		override protected function next():void
		{
			switch( _status )
			{
				case SimpleTask.NONE     : initVKApi(); break;
				case INITIALIZING_VK_API : checkRunningApplicationCopy(); break; 
				case CHECKING_RUNNING_APPLICATION_COPY : getAppUsers(); break;
				case GETTING_APP_USERS   : getUserInfo(); break;
				case GETTING_USER_INFO   : loadSettings(); break;
				case LOADING_SETTINGS    : configureAPI(); connect(); break;
				case CONNECTING          : if ( api.logedIn ) orderAppUsers() else register(); break;
				case REGISTERING         : orderAppUsers(); break;
				case ORDERING_APP_USERS  : browseExamples(); break;
				case BROWSING_EXAMPLES   : loadProjectInfoIfNeeded(); break;
				default : 
					 api.removeAllObjectListeners( this );
					 appUsersUIDS = null;
					 _status = SimpleTask.DONE;
					 dispatchEvent( new Event( Event.COMPLETE ) );
					 return;
			}
			
			super.next();
		}
		
		private function onVKApiInitialized( e : IFlashEvent ) : void
		{
			VKApi.impl.removeListener( IFlashEvent.CONNECTION_INIT, onVKApiInitialized );
			next();
		}
		
		private function initVKApi() : void
		{
			_status = INITIALIZING_VK_API;
		
			if ( VKApi.init( stage ) )
			{
				params = VKApi.params;
				
				if ( VKApi.initialized )
				{
					next();
				}
				else
				{
					VKApi.impl.addListener( IFlashEvent.CONNECTION_INIT, onVKApiInitialized, this );	
				}	
			}
			else
			{
				next();
			}
		}
		
		/*
		Проверка на копии уже запущенных приложений от имени одинаковых пользователей
		*/
		
		private function checkRunningApplicationCopy() : void
		{
			_status = CHECKING_RUNNING_APPLICATION_COPY;
			initLocalConnection();
		}
		
		private var lc : LocalConnection;
		
		private function initLocalConnection() : void
		{
			if ( ! LocalConnection.isSupported )
			{
				next();
				return;
			}
				
			lc = new LocalConnection();
			lc.addEventListener( StatusEvent.STATUS, onLocalConnectionReplyStatus );
			lc.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onLocalConnectionError, true, 1000 );
			
			sendMessageToAnotherCopy();
		}
		
		private function sendMessageToAnotherCopy() : void
		{
			try
			{
			  lc.send( VKApi.LOCAL_CONNECTION_NAME, 'checkRunningApplicationHandler' );
		    }
		    catch( error : Error )
		    {
			  uninitLocalConnection();
			  next();
		    }
		}
		
		private function uninitLocalConnection() : void
		{
			lc.removeEventListener( StatusEvent.STATUS, onLocalConnectionReplyStatus );
			lc.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onLocalConnectionError );
			
			lc = null;
		}
		
		private function onLocalConnectionError( e : Event ) : void
		{
			uninitLocalConnection();
			next();
		}
		
		private function onLocalConnectionReplyStatus( e : StatusEvent ) : void
		{
			switch( e.level )
			{
				case "status" : dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, "Another aplication's instance already launched", 15900 ) );
								sendMessageToAnotherCopy();
					            return;
				
				default : next();
					      uninitLocalConnection();
					      return;
			}
		}
		
		/*
		Проверка на копии уже запущенных приложений от имени одинаковых пользователей
		*/
		
		private var appUsersUIDS : Array;
		
		private function onGotAppUsers( data : Object ) : void
		{
			if ( data && ( data as Array ) )
			{
				appUsersUIDS = data as Array;
			}
			else
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, "Error while friends.getAppUsers", 100 ) );
				return;
			}
			
			next();
		}
		
		private function onErrorAppUsers( data : Object ) : void
		{
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, "Error while friends.getAppUsers", 100 ) );
		}
		
		private function getAppUsers() : void
		{
			_status = GETTING_APP_USERS;
			
			if ( VKApi.initialized )
			{
				VKApi.impl.api( 'friends.getAppUsers', null, onGotAppUsers, onErrorAppUsers ); 
			}
			else
			{
				next();
			}
		}
		
		private function onAppUsersOrdered( e : OrderUserListEvent ) : void
		{
			api.removeListener( OrderUserListEvent.ORDER_USER_LIST, onAppUsersOrdered );
			
			var orderedUsers : Array = new Array();
			
			for ( var i : int = 0; i < e.orderedList.length; i ++ )
			{
				for ( var j : int = 0; j < VKApi.appUsers.length; j ++ )
				{
					if ( VKApi.appUsers[ j ].uid == e.orderedList[ i ].uid )
					{
						orderedUsers.push( VKApi.appUsers[ j ] ); 
						break;    
					}
				}
			}
			
			VKApi.appUsers = orderedUsers;
			
			next();
		}
		
		private function orderAppUsers() : void
		{
			_status = ORDERING_APP_USERS;
			
			if ( appUsersUIDS && appUsersUIDS.length > 0 )
			{
				api.addListener( OrderUserListEvent.ORDER_USER_LIST, onAppUsersOrdered, this );
				api.orderUserList( appUsersUIDS );
			}
			else
			{
				next();
			}
		}
		
		private function getUserInfo() : void
		{
			_status = GETTING_USER_INFO;
			
			if ( VKApi.initialized )
			{
				appUsersUIDS.push( params.viewer_id );
				VKApi.impl.api( 'users.get', { user_ids : appUsersUIDS.join(), fields : 'first_name, last_name, nickname, screen_name, photo_50' }, onGetUserComplete, onGetUserError );	
			}
			else
			{
				VKApi.userInfo = { uid : '0', first_name : 'Иван', last_name : 'Петричко', nickname : 'Petrichko', photo_50 : 'http://cs418317.vk.me/v418317102/352b/SmJmqk-FPk0.jpg' };
				next();
			}
		}
		
		private function onGetUserComplete( data : Object ) : void
		{
			if ( data.length == 0 )
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, "Can't find current user info", 100 ) );
				return;
			}
			
			for ( var i : int = 0; i < data.length; i ++ )
			{
				if ( data[ i ].uid.toString() == params.viewer_id )
				{
					VKApi.userInfo = data.splice( i, 1 )[0];
					break;
				}
			}
			
			VKApi.appUsers = data as Array;
			
			next();
		}
		
		private function onGetUserError( data : Object ) : void
		{
			dispatchEvent( new ErrorEvent( 'Error while getting user info' ) );
		}
		
		private function configureAPI() : void
		{
			api = MainAPI.impl;
			api.addListener( AMFErrorEvent.ERROR, onAPIError, this, 1000 );
		}
		
		private function onAPIError( e : AMFErrorEvent ) : void
		{
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.text, e.errorID ) );
			e.stopImmediatePropagation();
		}
		
		private function onConnect( e : UserEvent ) : void
		{
			api.removeListener( UserEvent.CONNECT, onConnect );
			next();
		}
		
		private function connect() : void
		{
			_status = CONNECTING;
			api.addListener( UserEvent.CONNECT, onConnect, this );
			
			api.connect( params ? params.viewer_id : '0' );
		}
		
		private function onRegister( e : UserEvent ) : void
		{
			api.removeListener( UserEvent.REGISTER, onRegister );
			
			if ( ! api.logedIn )
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, "Can't register new user :(", 1000 ) );
			}
			else
			{
				next();
			}
		}
		
		private function register() : void
		{
			_status = REGISTERING;
			api.addListener( UserEvent.REGISTER, onRegister, this );
			api.register( params ? params.viewer_id : '0' );
		}
		
		private function onBrowseExamples( e : BrowseProjectEvent ) : void
		{
			api.removeListener( BrowseProjectEvent.BROWSE_EXAMPLES, onBrowseExamples );
			next();
		}
		
		private function browseExamples() : void
		{
			_status = BROWSING_EXAMPLES;
			
			api.addListener( BrowseProjectEvent.BROWSE_EXAMPLES, onBrowseExamples, this );
			api.browseExamples();
		}
		
		private function onLoadingSettingsComplete( e : Event ) : void
		{
			removeLoaderListeners();
			
			Settings.parseSettings( new XML( loader.data ) );
			Settings.loaded = true; //Сообщаем что настройки загружены
			Settings.notifier.dispatchEvent( new Event( Event.CHANGE ) ); //Посылаем сообщение об изменении настроек
			loader = null;
			next();
		}
		
		private function onLoadingSettingsError( e : IOErrorEvent ) : void
		{
			removeLoaderListeners();
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.text, e.errorID ) );
			loader = null;
		}
		
		private function removeLoaderListeners() : void
		{
			loader.removeEventListener( Event.COMPLETE, onLoadingSettingsComplete );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onLoadingSettingsError );
		}
		
		private function loadSettings() : void
		{
			_status = LOADING_SETTINGS;
			
			loader = new URLLoader();
			loader.addEventListener( Event.COMPLETE, onLoadingSettingsComplete );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onLoadingSettingsError );
			loader.load( new URLRequest( 'data.xml?time=' + new Date().time.toString() ) );
		}
		
		private function onGotProjectInfo( e : GetProjectInfoEvent ) : void
		{
			api.removeListener( GetProjectInfoEvent.GET_PROJECT_INFO, onGotProjectInfo );
			
			if ( ! e.error )
			{	
				params[ Settings.PROJECT_ID_PARAM_NAME ] = e.info;
			}
			
			next();
		}
		
		private function loadProjectInfoIfNeeded() : void
		{
			_status = LOAD_PROJECT_INFO_IF_NEEDED;
			
			trace( 'encodedId', AgeCrypt.encode( '12334' ) );
			
			if ( params && params.hasOwnProperty( 'hash' ) )
			{
				try
				{
					var urlVariables : URLVariables = new URLVariables( params.hash );
				}
				catch( error : Error )
				{
					next();
					return;
				}
				
				if ( urlVariables.hasOwnProperty( Settings.PROJECT_ID_PARAM_NAME ) )
				{
					var pid : String = AgeCrypt.decode( urlVariables[ Settings.PROJECT_ID_PARAM_NAME ] );
					
					//Проверяем, является ли идентификатор числом
					if ( ! isNaN( parseFloat( pid ) ) )
					{
						api.addListener( GetProjectInfoEvent.GET_PROJECT_INFO, onGotProjectInfo, this );
						api.getProjectInfo( pid );
						
						return;
					}
				}
			}
			
			next();
		}
	}
}