package classes.api
{
	import flash.events.IEventDispatcher;
	
	public interface ICustomEventDispatcher extends IEventDispatcher
	{
		function addListener( type : String, listener : Function, caller : Object = null, priority : int = 0 ) : void
		function removeListener( type : String, listener : Function ) : void
		function removeAllObjectListeners( caller : Object ) : void
		function removeAllListeners() : void
	}
}