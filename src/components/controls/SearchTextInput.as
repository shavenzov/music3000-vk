package components.controls
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.events.FlexEvent;
	import mx.utils.StringUtil;
	
	import spark.components.TextInput;
	
	import components.controls.events.SearchtextInputEvent;
	import components.managers.PopUpManager;
	
	import skins.SearchTextInputSkin;
	
	public class SearchTextInput extends TextInput
	{
		[SkinPart(required="true")]
		public var searchButton : Button;
		[SkinPart(required="true")]
		public var resetButton : Button;
		
		public function SearchTextInput()
		{
			super();
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
		}
		
		private function onAddedToStage( e : Event ) : void
		{
			stage.addEventListener( MouseEvent.CLICK, onStageClick );
		}
		
		override protected function getCurrentSkinState():String
		{
			if ( ! stage )
			{
				return super.getCurrentSkinState();
			}
			
			if ( stage.focus == null &&
				prompt != null && prompt != "")
			{
				if (text.length == 0)
				{
					if (enabled && skin && skin.hasState("normalWithPrompt"))
						return "normalWithPrompt";
					if (!enabled && skin && skin.hasState("disabledWithPrompt"))
						return "disabledWithPrompt";
				}
			}
			return enabled ? "normal" : "disabled";
		}
		
		private function onStageClick( e : MouseEvent ) : void
		{
			if ( PopUpManager.numWindows > 0 )
			{
				return;
			}
			
			if ( ! DisplayObject( textDisplay ).hitTestPoint( e.stageX, e.stageY ) )
			{
				if ( text )
				{
					var changedText : String = StringUtil.trim( text );
					
					if ( changedText != text )
					{
						text = changedText;
					} 
				}
				
				stage.focus = null; 
				invalidateSkinState();
			}
		}
		
		override protected function createChildren():void
		{
			setStyle( 'skinClass', skins.SearchTextInputSkin );
			super.createChildren();
		}
		
		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded( partName, instance );
			
			if ( instance == searchButton )
			{
				searchButton.addEventListener( MouseEvent.CLICK, onSearchClick );
			}
			else
			if ( instance == resetButton )
			{
				resetButton.addEventListener( MouseEvent.CLICK, onResetClick );
			}
		}
		
		private function onSearchClick( e : MouseEvent ) : void
		{
			dispatchEvent( new FlexEvent( FlexEvent.ENTER ) );
		}
		
		private function onResetClick( e : MouseEvent ) : void
		{
			text = null;
			dispatchEvent( new SearchtextInputEvent( SearchtextInputEvent.RESET ) );
		}
	}
}