package classes.api
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class CustomEventDispatcher extends EventDispatcher implements ICustomEventDispatcher
	{
		private var listeners : Vector.<Listener> = new Vector.<Listener>();
		
		public function CustomEventDispatcher(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function addListener( type : String, listener : Function, caller : Object = null, priority : int = 0 ) : void
		{
			listeners.push( new Listener( type, listener, caller ) );
			super.addEventListener( type, listener, false, priority );
			//trace( 'add',  type, caller, 'numListeners', listeners.length, this );
		}
		
		public function removeListener( type : String, listener : Function ) : void
		{
			var i : int = 0;
			var l : Listener;
			
			while( i < listeners.length )
			{
				l = listeners[ i ];
				
				if ( ( l.type == type ) && ( l.listener == listener ) )
				{
					super.removeEventListener( type, listener );
					listeners.splice( i, 1 );
					break;
				}
				
				i ++;
			}
			//trace( 'remove', type, 'numListeners', listeners.length, this );
		}
		
		public function removeAllObjectListeners( caller : Object ) : void
		{
			var l : Listener;
			
			for ( var i : int = listeners.length - 1; i >= 0; i -- )
			{
				l = listeners[ i ];
				
				if ( l.caller == caller )
				{
					super.removeEventListener( l.type, l.listener );
					listeners[ i ] = null;
					listeners.splice( i, 1 );
				}
			}
			
			//trace( 'numListeners', listeners.length, this );
		}
		
		public function removeAllListeners() : void
		{
			var l : Listener;
			
			for ( var i : int = listeners.length - 1; i >= 0; i -- )
			{
				l = listeners[ i ];
				super.removeEventListener( l.type, l.listener );
				listeners[ i ] = null;
			}
			
			listeners.length = 0;
			//trace( 'numListeners', listeners.length, this );
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			throw new Error( 'This method disabled...' );
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			throw new Error( 'This method disabled...' );
		}
		
	}
}

class Listener
{
	public var type : String;
	public var listener : Function;
	public var caller : Object;
	
	public function Listener( type : String, listener : Function, caller : Object ) 
	{
		this.type = type;
		this.listener = listener;
		this.caller = caller;
	}
}