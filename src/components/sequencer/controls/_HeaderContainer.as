package components.sequencer.controls
{
	import components.sequencer.controls.events.HeaderContainerEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	
	import mx.core.IUITextField;
	import mx.core.UIComponent;
	import mx.core.UIFTETextField;
	
	[Style(name="numberTextStyle", type="String", inherit="no")]
	public class _HeaderContainer extends UIComponent
	{
		[Embed(source='/assets/assets.swf', symbol='track_header')]
		private var BGClass : Class;
		private var _bg : Sprite;
		
		private var _textLabel    : IUITextField;
		private var _text : String = 'track 01';
		
		private var _numberLabel : IUITextField;
		private var _number : String = '01';
		
		private var _inEditMode : Boolean;
		private var _modeChanged : Boolean;
		
		public function _HeaderContainer()
		{
			super();
		}
		
		public function get inEditMode() : Boolean
		{
			return _inEditMode;
		}	
		
		/**
		 * Текст заголовка 
		 * @return 
		 * 
		 */		
		public function get text() : String
		{
			return _text;
		}
		
		public function set text( value : String ) : void
		{
			_text = value;
			invalidateProperties();
		}
		
		/**
		 * Номер, в правом верхнем углу 
		 * @return 
		 * 
		 */		
		public function get number() : String
		{
			return _number;
		}
		
		public function set number( value : String ) : void
		{
			_number = value;
			invalidateProperties();
		}	
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_bg = new BGClass() as Sprite;
			
			_textLabel   = IUITextField( createInFontContext( UIFTETextField ) );
			_numberLabel = IUITextField( createInFontContext( UIFTETextField ) );
			
			var nStyleName : String = getStyle( 'numberTextStyle' );
			if ( nStyleName )
			{
				_numberLabel.styleName = nStyleName;
			}	
			
			addChild( _bg );
			addChild( _textLabel );
			addChild( _numberLabel );
			
			doubleClickEnabled = true;
			addEventListener( MouseEvent.DOUBLE_CLICK, onDblClick );
		}
		
		private function onDblClick( e : MouseEvent ) : void
		{
			if ( ! _inEditMode )
			{
				switchEditMode( true );
			}	
		}	
		
		private function switchEditMode( editing : Boolean ) : void
		{
			_inEditMode = editing;
			_modeChanged = true;
			
			
			dispatchEvent( new HeaderContainerEvent( _inEditMode ? HeaderContainerEvent.START_CHANGING : HeaderContainerEvent.CHANGED, _text ) );
				
			
			invalidateProperties();
			invalidateDisplayList();
		}	
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _text != _textLabel.text )
			{
				_textLabel.text = _text;
			}
			
			if ( _number != _numberLabel.text )
			{
				_numberLabel.text = _number;
			}
			
			if ( _modeChanged )
			{
				if ( _inEditMode )
				{
					stage.addEventListener( MouseEvent.CLICK, onStageClick );
					_textLabel.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
					_textLabel.addEventListener( Event.CHANGE, onChange );
					_textLabel.type = TextFieldType.INPUT;
					_textLabel.selectable = true;
					_textLabel.setSelection( 0, _text.length );
					_textLabel.setFocus();
				}	
				else
				{
					stage.removeEventListener( MouseEvent.CLICK, onStageClick )
					_textLabel.removeEventListener( KeyboardEvent.KEY_UP, onKeyUp );
					_textLabel.removeEventListener( Event.CHANGE, onChange );
					
					_textLabel.setSelection( 0, 0 );
					_textLabel.type = TextFieldType.DYNAMIC;
					_textLabel.selectable = false;
					
					_textLabel.text = _text;
				}	
					
				_modeChanged = false;
			}	
		}
		
		private function onChange( e : Event ) : void
		{
			_text = _textLabel.text;
		}	
		
		private function onStageClick( e : MouseEvent ) : void
		{
			if ( ! hitTestPoint( e.stageX, e.stageY ) )
			{
				switchEditMode( false );
			}	
		}	
		
		private function onKeyUp( e : KeyboardEvent ) : void
		{
			if ( e.keyCode == Keyboard.ENTER )
			{
				switchEditMode( false );	
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
		  super.updateDisplayList( unscaledWidth, unscaledHeight );
		  
		  _bg.width = unscaledWidth;
		  _bg.height = unscaledHeight;
		  
		  _numberLabel.setActualSize( _numberLabel.getExplicitOrMeasuredWidth(), _numberLabel.getExplicitOrMeasuredHeight() );
		  _numberLabel.move( unscaledWidth - _numberLabel.width - 2, ( unscaledHeight - _numberLabel.height ) / 2 );
		  
		  
		  _textLabel.setActualSize( unscaledWidth - _numberLabel.width - 4, _textLabel.getExplicitOrMeasuredHeight() ); 
		  _textLabel.move( 2, ( unscaledHeight - _textLabel.height ) / 2 ); 
		}	
	}
}