package handler
{
	import classes.api.ICustomEventDispatcher;
	
	public interface IChannel extends ICustomEventDispatcher
	{
		function repair() : void;
	}
}