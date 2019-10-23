package components.controls
{
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import flashx.textLayout.formats.TextDecoration;
	
	import mx.controls.Label;
	import mx.controls.LinkButton;
	import mx.core.UIComponent;
	import mx.states.State;
	
	[Event(type="flash.events.Event", name="saveButtonClick")]
	public class SaveLabel extends UIComponent
	{
		private var icon  : DisplayObject;
		private var saveButton : mx.controls.LinkButton;
		public var label : Label;
		
		public function SaveLabel()
		{
			super();
			focusEnabled = false;
			tabEnabled = false;
			states = [ new State( { name : 'saved' } ), new State( { name : 'saving' } ), new State( { name : 'needToSave' } ) ];
		}
		
		public function get text() : String
		{
			return label.text;
		}
		
		public function set text( value : String ) : void
		{
			label.text = value;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			label = new Label();
			label.toolTip = 'Щелкни для изменения свойств микса';
			
			label.addEventListener( MouseEvent.ROLL_OVER, onRollOver );
			label.addEventListener( MouseEvent.ROLL_OUT, onRollOut );
			label.addEventListener( MouseEvent.CLICK, onClick );
			
			addChild( label );
			
			currentState = 'saved';
		}
		
		private function onClick( e : MouseEvent ) : void
		{
			dispatchEvent( new Event( 'nameClick' ) );
		}
		
		override protected function stateChanged(oldState:String, newState:String, recursive:Boolean):void
		{
			super.stateChanged( oldState, newState, recursive );
			
			if ( icon )
			{
				removeChild( icon );
				icon = null;
			}
			
			if ( saveButton )
			{
				saveButton.removeEventListener( MouseEvent.CLICK, onSaveButtonClick );
				removeChild( saveButton );
				saveButton = null;
			}
			
			if ( newState == 'saved' )
			{
				
			}
			else
			if ( newState == 'saving' )
			{
				icon = new Indicator();
				icon.width = 20;
				icon.height = 20;
				
				addChild( icon );
				
			}
			else
			if ( newState == 'needToSave' )
			{
				saveButton = new mx.controls.LinkButton();
				saveButton.toolTip = 'Щелкни для сохранения микса';
				saveButton.useHandCursor = false;
				saveButton.focusEnabled = false;
				saveButton.tabEnabled = false;
				saveButton.setStyle( 'icon', Assets.SAVE_ICON );
				saveButton.addEventListener( MouseEvent.CLICK, onSaveButtonClick );
				addChild( saveButton );
			}
			
			invalidateDisplayList();
		}
		
		private function onSaveButtonClick( e : MouseEvent ) : void
		{
			dispatchEvent( new Event( 'saveButtonClick' ) );
		}
		
		override protected function measure():void
		{
			measuredWidth  = label.getExplicitOrMeasuredWidth();
			measuredHeight = label.getExplicitOrMeasuredHeight();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			label.setActualSize( unscaledWidth, unscaledHeight );
			
			if ( icon )
			{
				icon.x = unscaledWidth + 12;
				icon.y = 10;
			}
			
			if ( saveButton )
			{
				saveButton.setActualSize( 24, 24 );
				saveButton.move( unscaledWidth, ( unscaledHeight - saveButton.height ) / 2 );
			}
		}
		
		private function onRollOver( e : MouseEvent ) : void
		{
			label.setStyle( 'textDecoration', TextDecoration.UNDERLINE );
		}
		
		private function onRollOut( e : MouseEvent ) : void
		{
			label.setStyle( 'textDecoration', TextDecoration.NONE );
		}
	}
}