package classes.api.social.vk
{
	import flash.display.Stage;
	
	import classes.api.social.vk.events.CustomEvent;

	public class VKApi
	{
		/**
		 * Параметры инициализации 
		 */		
		public static var params : Object;
		
		/**
		 * Информация о пользователе 
		 */		
		public static var userInfo : Object;
		
		public static function get LOCAL_CONNECTION_NAME() : String
		{
			return Settings.LOCAL_CONNECTION_NAME + ( params ? params.viewer_id : '' );
		}
		
		/**
		 * Список друзей установивших приложение 
		 */		
		public static var appUsers : Array;
		
		    private static var _impl : APIConnection;
			
			private static function onSettingsChanged( e : CustomEvent ) : void
			{
				params.api_settings = uint( e.params[ 0 ] );
			}
			
			/**
			 * 
			 * @param stage
			 * @return false - если инициализация завершилась ошибкой 
			 * 
			 */			
			public static function init( stage : Stage ) : Boolean
			{
				if ( _impl )
					throw new Error( 'API already initialized.' );
				
				if ( stage.loaderInfo.parameters.viewer_id != undefined )
				{
					params = stage.loaderInfo.parameters;
					_impl = new APIConnection();
					_impl.addListener( 'onSettingsChanged', onSettingsChanged, stage );
					return true;
				}
				
				return false;
			}
			
			public static function get initialized() : Boolean
			{
				return _impl ? _impl.initialized : false;
			}
			
			public static function get impl() : APIConnection
			{
				if ( ! _impl )
				{
					throw new Error( 'API not initialized. Call init first.' );
				}
				
				return _impl;
			}
			
			public static function formatUserName( user : Object ) : String
			{
				if ( user.nickname )
				{
					return user.nickname;
				}
				
				if ( user.first_name )
				{
					return user.first_name;
				}
				
				return user.last_name;
			}
			
			public static function get userName() : String
			{
				return formatUserName( userInfo );
			}
			
			public static function formatUserFullName( user : Object ) : String
			{
				var name : String = '';
				
				if ( user.nickname )
				{
					name = user.nickname;
				}
				else
				{
					if ( user.first_name )
					{
						name = user.first_name;
					}
					
					if ( user.last_name )
					{
						name += ' ' + user.last_name; 
					}
				}
				
				return name;
			}
			
			public static function get userFullName() : String
			{
				return formatUserFullName( userInfo );
			}
		  }
		
	
}