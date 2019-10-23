package components.utils
{
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	import mx.core.UIComponent;

	public class ErrorUtils
	{
		private static function showDeferred(target:UIComponent):void {
			target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
			target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		} 
		
		public static function show( target : UIComponent, message : String ) : void
		{
			target.errorString = message;
			target.setFocus();
			setTimeout( showDeferred, 25, target );
		}
		
		public static function justShow( target : UIComponent ) : void
		{
			target.setFocus();
			setTimeout( showDeferred, 25, target );
		}
		
		public static function hide( target : UIComponent ) : void
		{
			target.errorString = null;
			target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
			target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		}
	}
}