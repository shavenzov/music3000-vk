package mx.managers
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class DoubleClickManager
	{
		/**
		 * Задержка для определяения двойного клика 
		 */		
		private static const DELAY_TIME  : Number = 200.0;
		private static var _delay_id1    : int = -1;
		private static var _delay_id2    : int = -1;
		private static var _source       : DisplayObject;
		
		private static var _event        : Event;
		
		public  static var double_click  : Boolean;
		
		private static function send( e : Event ) : void
		{
			if ( e )
			{
				_source.dispatchEvent( e );
			}	
		}	
		
		private static function dispatchAfterDelay1( e : Event ) : void
		{
			send( e );
			_delay_id1 = -1;
		}
		
		private static function setDelay1( e : Event ) : void
		{	
			_delay_id1 = setTimeout( dispatchAfterDelay1, DELAY_TIME, e );	
		}
		
		private static function clearDelay1() : void
		{
			clearTimeout( _delay_id1 );
			_delay_id1 = -1;
		}
		private static function dispatchAfterDelay2( e : Event ) : void
		{
			send( e );
			_delay_id2 = -1;
		}
		
		private static function setDelay2( e : Event ) : void
		{	
			_delay_id2 = setTimeout( dispatchAfterDelay2, DELAY_TIME, e );
		}
		
		private static function clearDelay2() : void
		{
			clearTimeout( _delay_id2 );
			_delay_id2 = -1;
		}
		
		public static function onMouseMove( e : MouseEvent ) : void
		{
			if ( ( _delay_id1 == -1 ) && ( _delay_id2 == -1 ) ) return;
			
			if ( _delay_id1 != -1 )
			{
				clearDelay1();
			}
			
			if ( _delay_id2 != -1 )
			{
				clearDelay2();
			}	
			
			send( _event );	
		}	
		
		public static function mouseDown( source : DisplayObject, event : Event = null ) : void
		{
		  _source = source;
		  _event  = event;
		  
		  if ( _delay_id1 == -1 )
		  {
			  	setDelay1( event );
		  }
		  else if ( ( _delay_id1 != -1 ) && ( _delay_id2 != -1 ) )
		  {
			  clearDelay2();
			  clearDelay1();
			  double_click = true;
		  }
		  
		  source.stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		}
		
		public static function mouseUp( event : Event ) : void
		{
		  _source.stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		  
		  if ( ! double_click )
		  {
			  if ( _delay_id2 == -1 )
			  {
				  setDelay2( event );
			  }
			  else 
			  {
				  clearDelay2();
			  }
		  }
		  
		  double_click = false;
		}	
	}
}