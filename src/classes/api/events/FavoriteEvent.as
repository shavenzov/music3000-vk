package classes.api.events
{
	import flash.events.Event;
	
	import classes.api.errors.APIError;
	
	public class FavoriteEvent extends Event
	{
		public static const ADD    : String = 'addToFavorite';
		public static const REMOVE : String = 'removeFromFavorite';
		
		/**
		 * Код выполненной операции 
		 */		
		public var id : int;
		/**
		 * Идентификатор библиотеки 
		 */		
		public var library : String;
		/**
		 * Идентификатор сэмпла 
		 */		
		public var hash    : String; 
		
		public function FavoriteEvent( type : String, id : int, library : String, hash : String )
		{
			super( type );
			
			this.id      = id;
			this.library = library;
			this.hash    = hash;
		}
		
		public function get error() : Boolean
		{
			return id < APIError.OK;
		}
		
		public function get errorCode() : int
		{
			if ( error ) return id;
			return APIError.OK;
		}
		
		override public function clone():Event
		{
			return new FavoriteEvent( type, id, library, hash );
		}
	}
}