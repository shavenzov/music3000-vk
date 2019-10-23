package classes.api
{
	import com.adobe.crypto.MD5;
	import com.serialization.Serialize;
	
	import flash.net.LocalConnection;
	
	import mx.core.mx_internal;
	
	import classes.api.data.UserInfo;
	import classes.api.errors.APIError;
	import classes.api.events.ProModeChangedEvent;
	import classes.api.events.UserEvent;
	import classes.api.social.vk.VKApi;
	
	use namespace mx_internal;

	public class SessionAPI extends AMFApi
	{
		private static const SECRET : String = "umFAlFfSC6htif9qGuXX";
		
		/**
		 * Информация о пользователе 
		 */		
		protected var _userInfo : UserInfo;
		
		/**
		 * Пользователь зашел в программу впервые 
		 */		
		private var _firstTime : Boolean;
		
		/**
		 * Необработанный вызов в результате потери сессии
		 */		
		private var lost_call : Call;
		
		/*
		Для проверки запущена ли копия приложения с таким же пользователем
		*/
		private var lc : LocalConnection;
		
		public function SessionAPI()
		{
			super();
		}
		
		private function initLocalConnection() : void
		{
			/*
			Для проверки запущена ли копия приложения тем же пользователем
			*/
			if ( ! lc )
			{
				lc = new LocalConnection();
				lc.client = this;
				lc.connect( VKApi.LOCAL_CONNECTION_NAME );	
			}
		}
		
		/*
		Для проверки запущена ли копия приложения тем же пользователем
		*/
		private function uninitLocalConnection() : void
		{
			if ( lc )
			{
				lc.close();
				lc = null;	
			}
		}
		
		/*
		Для проверки запущена ли копия приложения с таким же пользователем
		*/
		public function checkRunningApplicationHandler() : void
		{
			trace( 'LocalConnection message received' );
		}
		
		public function get firstTime() : Boolean
		{
			return _firstTime;
		}
		
		public function get logedIn() : Boolean
		{
			return _userInfo != null;
		}
		
		/**
		 * Идентификатор соц сети ( для восстановления сессии )
		 */		
		private var net       : String;
		/**
		 * Идентификатор пользователя в соц сети ( для восстановления сессии ) 
		 */		
		private var netUserID : String;
		
		private function getConnectionParams( netUserID : String, net : String ) : Array
		{
			return [ 'API.connect', onConnect, net, netUserID, MD5.hash( net + netUserID + SECRET ) ];
		}
		
		/**
		 * Пытаемся незаметно перелогинится если сессия истекла и продолжить выполнение комманд 
		 * @param responds
		 * @return 
		 * 
		 */		
		override protected function beforeSuccessCall( responds : Object ) : Boolean
		{  
		   if ( responds is Number )
			{
				if ( responds == APIError.SESSION_NOT_FOUND )
				{
					lost_call = currentCall;
					
					unshiftQueue.apply( this, getConnectionParams( netUserID, net ) ); //Добавляем в очередь комманду получения сессии
					next();
					
					return false;
				}
			}
		   
			return true;
		}
		
		protected function updateUserInfo( responds : Object ) : void
		{
			var updated : Boolean;
			var lastUserInfo : UserInfo = _userInfo.clone();
			
			
			if ( responds.money != undefined )
			{
				_userInfo.money       = Number( responds.money );
				updated = true;
			}
			
			if ( responds.pro != undefined )
			{
				_userInfo.pro = Serialize.toBoolean( responds.pro );
				
				if ( _userInfo.pro )
				{
					dispatchEvent( new ProModeChangedEvent( ProModeChangedEvent.PRO_ACTIVATED ) );
					trace( 'pro_activated' );
				}
				else
				{
					dispatchEvent( new ProModeChangedEvent( ProModeChangedEvent.PRO_EXPIRED ) );
					trace( 'pro_expired' );
				}
				
				updated = true;
			}
			
			if ( responds.pro_expired != undefined )
			{
				_userInfo.pro_expired = Serialize.timeStampToDate( responds.pro_expired );
				updated = true;
			}
			
			if ( updated )
			{
				dispatchEvent( new UserEvent( UserEvent.UPDATE, _userInfo, lastUserInfo ) );
				trace( 'updateUserInfo' );
			}	
		}
		
		/**
		 *  
		 * @param responds
		 * @param eventType
		 * @return true, если все нормально 
		 * 
		 */		
		private function parseUser( responds : Object, eventType : String ) : Boolean
		{
			if ( responds is Number )
			{
				dispatchEvent( new UserEvent( eventType, null, null, int( responds  ) ) );
				return false;
			}
			
			_userInfo = parseUserInfo( responds );
			
			//Если произошло восстановление сессии,
			if ( lost_call )
			{
				lost_call.params[ 0 ] = _userInfo.session_id;
				queue.unshift( lost_call );
				
				lost_call = null;
			}
			
			dispatchEvent( new UserEvent( eventType, _userInfo ) );
			
			return true;	
		}
		
		protected function parseUserInfo( data : Object ) : UserInfo
		{
			var info : UserInfo = new UserInfo();
			
			if ( data.hasOwnProperty( 'registered' ) )
			{
				info.registered  = Serialize.timeStampToDate( data.registered );
			}
			
			if ( data.hasOwnProperty( 'loged_in' ) )
			{
				info.loged_in    = Serialize.timeStampToDate( data.loged_in );
			}
			
			if ( data.hasOwnProperty( 'pro_expired' ) )
			{
				info.pro_expired = Serialize.timeStampToDate( data.pro_expired );
			}
			
			if ( data.hasOwnProperty( 'pro' ) )
			{
				info.pro         = Serialize.toBoolean( data.pro );
			}
			
			if ( data.hasOwnProperty( 'time' ) )
			{
				info.time        = int( data.time );
			}
			
			if ( data.hasOwnProperty( 'money' ) )
			{
				info.money       = Number( data.money );
			}
			
			if ( data.hasOwnProperty( 'session_id' ) )
			{
				info.session_id  = String( data.session_id );
			}
			
			if ( data.hasOwnProperty( 'id' ) )
			{
				info.id          = int( data.id );
			}
			
			if ( data.hasOwnProperty( 'net_user_id' ) )
			{
				info.netUserId = data.net_user_id;
			}
			
			if ( data.hasOwnProperty( 'inviteUserBonus' ) )
			{
				info.inviteUserBonus  = Number( data.inviteUserBonus );
			}
			
			return info;
		}
		
		private function onConnect( responds : Object, call : Call ) : void
		{
			parseUser( responds, UserEvent.CONNECT );
			
			initLocalConnection();
		}
		
		private function onRegister( responds : Object, call : Call )  : void
		{
			_firstTime = true;
			
			parseUser( responds, UserEvent.REGISTER );
			
			initLocalConnection();
		}
		
		public function connect( netUserID : String, net : String = SocialNet.VK ) : void
		{
			uninitLocalConnection();
			
			this.netUserID = netUserID;
			this.net       = net;
			super.call.apply( this, getConnectionParams( netUserID, net ) );
		}
		
		public function register( netUserID : String, net : String = SocialNet.VK ) : void
		{
			uninitLocalConnection();
			super.call( 'API.register', onRegister, net, netUserID, MD5.hash( net + netUserID + SECRET ) );
		}
		
		override public function call(func:String, callback:Function, ...params):void
		{
			params.unshift( func, callback, _userInfo.session_id ); //К каждому запросу добавляем идентификатор сессии
			super.call.apply( this, params );
		}
	}
}