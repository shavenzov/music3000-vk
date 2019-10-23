/**
* ...
* @author Shavenzov Denis
* @version 0.1
* @e-mail Snowbird666@gmail.com
* 
* Расширяет стандартный компонент Menu, кастомный ItemRenderer
*/
package components.menu
{
	import components.menu.renderers.MenuItemRenderer;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import mx.controls.Menu;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.Application;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.mx_internal;
	
	use namespace mx_internal;

	public class Menu extends mx.controls.Menu
	{
		public function Menu()
		{
			super();
			itemRenderer = new ClassFactory( MenuItemRenderer );
		}
		
		public static function createMenu(parent:DisplayObjectContainer, mdp:Object, showRoot:Boolean = true) : components.menu.Menu
		 {
		 	 var menu : components.menu.Menu = new components.menu.Menu();
                 menu.tabEnabled = false;
                 menu.owner = DisplayObjectContainer( FlexGlobals.topLevelApplication );
                 menu.showRoot = showRoot;
                 popUpMenu(menu, parent, mdp);
             return menu;
		 }
		 
		 public static function popUpMenu(menu:components.menu.Menu, parent:DisplayObjectContainer, mdp:Object):void
          {
            menu.mx_internal::parentDisplayObject = parent ?
                                   parent :
                                   DisplayObject( FlexGlobals.topLevelApplication );

           if (!mdp)
               mdp = new XML();

           menu.supposedToLoseFocus = true;
           menu.dataProvider = mdp;
         }
         
        override protected function drawHighlightIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void
	    {
	   	  
	    }
	   
	    override protected function drawSelectionIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void
	     {
	   	  
	     }
	}
}