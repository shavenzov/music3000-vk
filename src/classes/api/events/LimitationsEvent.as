package classes.api.events
{
	import classes.api.errors.APIError;
	
	import com.utils.StringUtils;
	
	import flash.events.Event;
	
	public class LimitationsEvent extends Event
	{
		public static const GOT_LIMITATIONS : String = 'GOT_LIMITATIONS';
		
		private var projects : int;
		
		public function LimitationsEvent( type : String, projects : int )
		{
			super( type );
			this.projects = projects; 
		}
		
		public function get projectsExceeded() : Boolean
		{
			return projects != APIError.OK;
		}
		
		public function get projectsErrorCode() : int
		{
			return projects;
		}
		
		override public function clone():Event
		{
			return new LimitationsEvent( LimitationsEvent.GOT_LIMITATIONS, projects );
		}
		
		public static function getErrorDescription( code : int, firstCharToUpperCase : Boolean = false ) : String
		{
			var result : String;
			
			if ( code == APIError.MAX_PROJECTS_FOR_BASIC_MODE_EXCEEDED )
			{
				result = 'превышено максимальное количество миксов для базового режима';
			}
			
			if ( code == APIError.MAX_PROJECTS_PER_DAY_EXCEEDED )
			{
				result = 'превышено максимальное количество новых миксов за день';
			}
			
			if ( firstCharToUpperCase )
			{
				return StringUtils.firstSymbolToUpperCase( result );
			}
			
			return result;
		}
	}
}