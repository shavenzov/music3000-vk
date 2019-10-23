package components.managers
{
	import components.managers.events.HintEvent;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.ToolTip;
	import mx.core.EdgeMetrics;
	import mx.core.FlexGlobals;
	import mx.core.IContainer;
	import mx.core.IToolTip;
	import mx.core.UIComponent;
	import mx.managers.ISystemManager;
	import mx.managers.ToolTipManager;
	import mx.styles.IStyleClient;

	public class HintManager
	{
		private static const _shells : Vector.<HintShell> = new Vector.<HintShell>();
		
		public static function hideAll() : void
		{
			for each( var shell : HintShell in _shells )
			{
				shell.hide();
			}
		}
		
		public static function show( data : Object, error : Boolean = false, target : Object = null, mouseInteraction : Boolean = true, time : int = -1, hideOther : Boolean = true ) : HintShell
		{
			if ( hideOther )
			{
				if ( _shells.length > 0 )
				{
					_shells[ _shells.length - 1 ].hide();
					_shells[ _shells.length - 1 ].client.validateProperties();
				}
			}
			
			if ( data == null )
			{
				data = '';
			}
			
			var hint  : UIComponent = ( data is String ) ? new ToolTip() : UIComponent( data );
			var shell : HintShell = new HintShell( hint, mouseInteraction );
			
			if ( error )
			{
				shell.delayTime *= 2;
				hint.maxWidth = 400;
				hint.styleName = 'errorTip';
			}
			
			if ( time != -1 )
			{
				shell.delayTime = time;
			}
			
			shell.addEventListener( HintEvent.HIDE, onHide );
			
			var sm : ISystemManager = FlexGlobals.topLevelApplication.systemManager as ISystemManager;
			
			hint.moduleFactory = sm;
			sm.topLevelSystemManager.toolTipChildren.addChild( hint );
			
			if ( hint is IToolTip )
			{
				IToolTip( hint ).text = String( data );
			}
			
			hint.validateNow();
			hint.validateNow();
			
			hint.setActualSize(
				hint.getExplicitOrMeasuredWidth(),
				hint.getExplicitOrMeasuredHeight());
			
			if ( ! target )
			{
				target = new Point( sm.stage.mouseX, sm.stage.mouseY );
			}
			
			if ( target is Point )
			{
				var pos : Point = getToolTipPos( target.x, target.y, sm.topLevelSystemManager.screen.width, sm.topLevelSystemManager.screen.height, hint.width, hint.height );
				    hint.move( pos.x, pos.y );
			}
			else if ( target is DisplayObject )
			{
				shell.target = UIComponent( target );
				positionTip( DisplayObject( target ), hint, sm.topLevelSystemManager.screen.width, sm.topLevelSystemManager.screen.height );
			}
			
			_shells.push( shell );
			
			ToolTipManager.hideImmediately();
			
			return shell;
		}
		
		private static const leftOffset : Number = 11;
		private static const topOffset  : Number = 11;
		
		private static function getToolTipPos( pointX : Number, pointY : Number, screenWidth : Number, screenHeight : Number,
										toolTipWidth : Number, toolTipHeight : Number ) : Point
		{
			pointX += leftOffset;
			pointY += topOffset;
			
			if ( pointX < 0 )
			{
				pointX = leftOffset;
			}
			else
				if ( ( pointX + toolTipWidth ) > screenWidth )
				{
					pointX = screenWidth - toolTipWidth - leftOffset;
				}
			
			if ( pointY < 0 )
			{
				pointY = topOffset;
			}
			else
				if ( ( pointY + toolTipHeight ) > screenHeight )
				{
					pointY = screenHeight - toolTipHeight - topOffset;
				}
			
			return new Point( pointX, pointY );
		}
		
		private static function positionTip( currentTarget : DisplayObject, currentToolTip : UIComponent, screenWidth : Number, screenHeight : Number ):void
		{
			var x:Number;
			var y:Number;
			
			
			
			
				var target : DisplayObject = IStyleClient( currentTarget ).getStyle( 'toolTipTarget' );
				
				if ( ! target )
				{
					target = currentTarget;
				}
				
				var targetGlobalBounds:Rectangle = getGlobalBounds( target, target.stage );
				
				var placementX : int = -1;
				var placementY : int = -1;
				var borderStyle : String;
				
				
				if (currentTarget is IStyleClient)
					borderStyle = IStyleClient(currentTarget).getStyle( 'toolTipPlacement' );
				
				if ( borderStyle )
				{
					switch ( borderStyle )
					{
						case "errorTipRight"      : placementX = 3; break;
						case "errorTipAbove"      : placementX = 1; placementY = 1; break;
						case "errorTipBelow"      : placementX = 0; placementY = 0; break;
						case "errorTipAboveRight" : placementX = 2; placementY = 2; break;
						case "errorTipBelowRight" : placementX = 4; break;
					} 	
				}
				
				//Если компонентом не определен вариант размещения, то определяем его
				if ( placementX == -1 )
				{
					//Определяем вариант размещения по оси Х
					if ( ( targetGlobalBounds.right - currentToolTip.width ) < 0 )
					{
						placementX = 0;
					}
					else
						if ( ( targetGlobalBounds.x + currentToolTip.width ) > screenWidth )
						{
							placementX = 2;
						}
						else
						{
							placementX = 1;
						}
					
					//Определяем вариант размещения по оси Y
					if ( ( targetGlobalBounds.y - currentToolTip.height ) < 0 )
					{
						placementY = 0;
					}
					else
						if ( ( targetGlobalBounds.bottom + currentToolTip.height ) > screenHeight )
						{
							placementY = 2;
						}
						else
						{
							placementY = 1;
						}
					
				}
				
				//Основной вариант размещения
				if ( 
					( ( placementX == 1 ) && ( placementY == 1 ) ) ||
					( ( placementX == 1 ) && ( placementY == 2 ) ) ||
					( ( placementX == 0 ) && ( placementY == 1 ) ) ||
					( ( placementX == 0 ) && ( placementY == 2 ) )
				)	
				{
					x = targetGlobalBounds.x;
					y = targetGlobalBounds.y - currentToolTip.height - 11;
					borderStyle = "errorTipAbove";
				}
				else
					if (
						( ( placementX == 0 ) && ( placementY == 0 ) ) ||
						( ( placementX == 1 ) && ( placementY == 0 ) ) 
					)
					{
						x = targetGlobalBounds.x;
						y = targetGlobalBounds.bottom;
						borderStyle = "errorTipBelow";
					}
					else
						if (
							( ( placementX == 2 ) && ( placementY == 2 ) ) ||
							( ( placementX == 2 ) && ( placementY == 1 ) )
						)
						{
							x = targetGlobalBounds.right - currentToolTip.width;
							y =  targetGlobalBounds.y -	currentToolTip.height - 11;
							borderStyle = "errorTipAboveRight";
						}
						else if ( placementX == 3 )
						{
							x = targetGlobalBounds.right;
							y = targetGlobalBounds.y - 5;
						}
						else
						{
							x = targetGlobalBounds.right - currentToolTip.width;
							y = targetGlobalBounds.bottom;
							borderStyle = "errorTipBelowRight";
						}
				
				if (currentToolTip is IStyleClient)
					IStyleClient(currentToolTip).setStyle("borderStyle", borderStyle);
			
			/*
				Корректировка с учетом viewMetrics, там где это надо
			*/	
			if ( currentToolTip is IContainer )
			{
				var metrics : EdgeMetrics = IContainer( currentToolTip ).viewMetrics;
				
				if ( ! isNaN( currentToolTip.explicitWidth ) )
				{
					x += metrics.right - metrics.left;
				}
				
				if ( ! isNaN( currentToolTip.explicitHeight ) )
				{
					y += metrics.bottom - metrics.top;
				}
			}
				
			currentToolTip.move(x, y);
		}
		
		private static function getGlobalBounds(obj:DisplayObject, parent:DisplayObject):Rectangle
		{
			var upperLeft : Point = new Point( 0, 0 );
			    upperLeft = obj.localToGlobal( upperLeft );
			    upperLeft = parent.globalToLocal( upperLeft );
				
				return new Rectangle( upperLeft.x, upperLeft.y, obj.width, obj.height );
		}
		
		private static function onHide( e : HintEvent ) : void
		{
			var shell : HintShell = HintShell( e.currentTarget );
			var i    : int = 0;
			
			//trace( shell.client, 'client removed' );
			
			shell.target = null;
			shell.removeEventListener( HintEvent.HIDE, onHide );
			
			var sm : ISystemManager = FlexGlobals.topLevelApplication.systemManager as ISystemManager;
			
			sm.topLevelSystemManager.toolTipChildren.removeChild( shell.client );
			
			while( i < _shells.length )
			{
				if ( _shells[ i ] == shell )
				{
					_shells[ i ] = null;
					_shells.splice( i, 1 );
				}	
				
				i ++;
			}	
		}	
	}
}