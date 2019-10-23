/**
* ...
* @author Shavenzov Denis
* @version 0.1
* @e-mail Snowbird666@gmail.com
* 
* Расширяет функционал стандартного PopUpManager. 
* Добавляет метод для автоматического центрирования PopUp окна при изменении размера окна браузера
* Добавляет метод отображения окна относительно середины курсора мыши
*/
package components.managers
{
	
	import components.controls.LabeledIndicator;
	import components.managers.events.PopUpEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.EdgeMetrics;
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	import mx.managers.ToolTipManager;
	
	public class PopUpManager
	{
		
		//Список открытых окон и указания что с ними делать при ресайзе
		private static var windows : Array;
		
		/**
		 * Диспатчер для отправки событий связанных с PopupManager (open/close) 
		 */		
		public static var dispatcher : EventDispatcher = new EventDispatcher();
		
		/**
		 * Общее количество открытых окон 
		 */		
		private static var _numWindows : uint = 0;
		
		public static function get numWindows() : uint
		{
			return _numWindows;
		}
		
		private static var indicator : LabeledIndicator;
		
		public static function showLoading( label : String = null ) : void
		{
			if ( ! indicator )
			{
				indicator = new LabeledIndicator();
				
				if ( label )
				{
					indicator.label = label;
				}
				
				addPopUp( indicator, DisplayObject( FlexGlobals.topLevelApplication ), true );
				centerPopUp( indicator );
			}
			else
			{
				indicator.label = label;
			}
		}
		
		public static function hideLoading() : void
		{
			if ( indicator )
			{
				removePopUp( indicator );
				indicator = null;
			}
		}
		
		public static function addPopUp( window:IFlexDisplayObject, parent:DisplayObject = null, modal:Boolean = false, childList:String = null ) : void
	     {
	     	ToolTipManager.hideImmediately();
			mx.managers.PopUpManager.addPopUp( window, parent ? parent : DisplayObject( FlexGlobals.topLevelApplication ), modal, childList );
			_numWindows ++;
			dispatcher.dispatchEvent( new PopUpEvent( PopUpEvent.OPEN, _numWindows, window ) );
	     }
	     
	    public static function bringToFront( popUp : IFlexDisplayObject ) : void
	     {
			mx.managers.PopUpManager.bringToFront( popUp );
	     }
	     
	    public static function centerPopUp( popUp:IFlexDisplayObject, auto : Boolean = true ) : void
	     {
	     	if ( ( auto ) && ( popUp.stage ) )
	     	 {
	     	 	if ( ! windows ) 
	     	 	 {
	     	 	   windows = new Array();
	     	 	   popUp.stage.addEventListener( Event.RESIZE, onStageResized ); 
	     	 	 }
	     	 	
	     	 	popUp.addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
				popUp.addEventListener( ResizeEvent.RESIZE, onStageResized );
	     	 	windows.push( new ResizeAction( popUp, true ) );
	     	 }
	     	 
			mx.managers.PopUpManager.centerPopUp( popUp );	 
	     }
		
		public static function centerAndResizePopUp( popUp:IFlexDisplayObject, auto : Boolean = true, paddings : EdgeMetrics = null ) : void
		{
			if ( ( auto ) && ( popUp.stage ) )
			{
				if ( ! windows ) 
				{
					windows = new Array();
					popUp.stage.addEventListener( Event.RESIZE, onStageResized ); 	
				}
				
				popUp.addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
				
				if ( ! paddings )
				{
					paddings = EdgeMetrics.EMPTY;
					
					if ( popUp as UIComponent )
					{
						
						paddings.top = UIComponent( popUp ).getStyle( 'paddingTop' );
						paddings.bottom = UIComponent( popUp ).getStyle( 'paddingBottom' );
						paddings.left = UIComponent( popUp ).getStyle( 'paddingLeft' );
						paddings.right = UIComponent( popUp ).getStyle( 'paddingRight' );
						
						if ( isNaN( paddings.top ) ) paddings.top = 0;
						if ( isNaN( paddings.bottom ) ) paddings.bottom = 0;
						if ( isNaN( paddings.left ) ) paddings.left = 0;
						if ( isNaN( paddings.right ) ) paddings.right = 0;
						
					}
				}	
				 	
				
				windows.push( new ResizeAction( popUp, false, true, paddings ) );
			}
			
			resizePopUp( popUp, paddings );
		}
	     
	    public static function centerToMousePopUp( popUp : IFlexDisplayObject ) : void
	     {
	     	if ( popUp.stage )
	     	 {
	     	 	popUp.x = popUp.stage.mouseX - popUp.width / 2;
		        popUp.y = popUp.stage.mouseY - popUp.height / 2;
		 
		        if ( ( popUp.x + popUp.width ) > popUp.stage.stageWidth ) popUp.x = popUp.stage.stageWidth - popUp.width;
		        if ( ( popUp.y + popUp.height ) > popUp.stage.stageHeight ) popUp.y = popUp.stage.stageHeight - popUp.height;
		        
		        if ( popUp.x < 0 ) popUp.x = 0;
		        if ( popUp.y < 0 ) popUp.y = 0;  
	     	 }
	     } 
	     
	    public static function createPopUp( parent:DisplayObject, className:Class, modal:Boolean = false, childList:String = null) : IFlexDisplayObject 
	     {
			ToolTipManager.hideImmediately();
			
			_numWindows ++;
			
			var window : IFlexDisplayObject = mx.managers.PopUpManager.createPopUp( parent, className, modal, childList );
			
			dispatcher.dispatchEvent( new PopUpEvent( PopUpEvent.OPEN, _numWindows, window ) );
			
			
			return window;
	     }
	     
	    public static function removePopUp( popUp : IFlexDisplayObject ) : void
	     {
			mx.managers.PopUpManager.removePopUp( popUp );
			_numWindows --;
			dispatcher.dispatchEvent( new PopUpEvent( PopUpEvent.CLOSE, _numWindows, popUp ) );
	     }
		
		public static function removeAllPopUps() : void
		{
			mx.managers.PopUpManager.removeAllPopUps();
			_numWindows = 0;
			dispatcher.dispatchEvent( new PopUpEvent( PopUpEvent.CLOSE, _numWindows, null ) );
		}
	      
	    private static function onRemovedFromStage( e : Event ) : void
	     {
	     	  for ( var i : int = 0; i < windows.length; i ++ )
			  {
				  var window : IFlexDisplayObject = windows[ i ].window;
				  
				  if ( IFlexDisplayObject( e.target ) == window )
				  {
					  if ( windows.length == 1 ) window.stage.removeEventListener( Event.RESIZE, onStageResized );
					  window.removeEventListener( ResizeEvent.RESIZE, onStageResized );
					  windows.splice( i, 1 );
				  }
			  }
				  
	     	   if ( windows.length == 0 ) windows = null;
	     }
	    
	    private static function onStageResized( e : Event ) : void
	     {
	     	for ( var i : int = 0; i < windows.length; i ++ )
			{
				var window : IFlexDisplayObject = windows[ i ].window;
				
				if ( windows[ i ].resize )
				{
				  resizePopUp( window, windows[ i ].paddings );
				}
				else if ( windows[ i ].center )
				{
					mx.managers.PopUpManager.centerPopUp( window );
				}	
			}	
	     }
		
		private static function resizePopUp( popUp :  IFlexDisplayObject, paddings : EdgeMetrics ) : void
		{
			if ( popUp.stage )
			{
				var stageWidth  : Number = popUp.stage.stageWidth;
				var stageHeight : Number = popUp.stage.stageHeight;
				var newWidth    : Number = stageWidth - paddings.left - paddings.right;
				var newHeight   : Number = stageHeight - paddings.top - paddings.bottom;
				var window      : UIComponent = UIComponent( popUp );
				
				window.move( paddings.left, paddings.top );
				
				if ( ! isNaN( window.minWidth ) )
				{
					if ( window.minWidth < newWidth )
						window.explicitWidth = newWidth;
				}
				else window.explicitWidth = newWidth;
				
				if ( ! isNaN( window.minHeight ) )
				{
					if ( window.minHeight < newHeight )
						window.explicitHeight = newHeight;
				}
				else window.explicitHeight = newHeight;
				
				
				window.invalidateSize();	
			}
		}	
	}	
}
import mx.core.EdgeMetrics;
import mx.core.IFlexDisplayObject;

class ResizeAction
{
	public var window   : IFlexDisplayObject;
	public var center   : Boolean;
	public var resize   : Boolean;
	public var paddings : EdgeMetrics;
	
	public function ResizeAction( window : IFlexDisplayObject, center : Boolean, resize : Boolean = false, paddings : EdgeMetrics = null )
	{
		super();
		this.window = window;
		this.center = center;
		this.resize = resize;
		this.paddings = paddings;
	}
}
