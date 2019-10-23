package components.controls.timeScreenClasses
{
	import classes.events.ChangeBPMEvent;
	
	import com.utils.TimeUtils;
	
	import components.controls.PopupVSlider;
	import components.controls.timeScreenClasses.events.DisplayEvent;
	import components.managers.PopUpManager;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;

	public class TempoDisplay extends Display
	{
		private var icon : Sprite;
		
		private var slider : PopupVSlider;
		
		private var _bpm : Number = 0;
		/**
		 * Предыдущее значение темпа 
		 */		
		private var _lastBPM : Number;
		
		private var inputTempo : TextField;
		
		public function TempoDisplay()
		{
			super();
		}
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			if ( _bpm != value )
			{
				_lastBPM = _bpm;
				_bpm = value;
				invalidateProperties();
			}
		}
		
		override protected function createChildren() : void
		{
			super.createChildren();
			
			icon = new Assets.METRONOME_ICON_ORANGE();
			
			addChild( icon );
			
			numDigits = 3;
			
			addEventListener( MouseEvent.CLICK, onClick );
			
			setToolTip();
		}
		
		private function setToolTip() : void
		{
			toolTip = 'Щелкни для изменения темпа';	
		}
		
		private function onClick( e : MouseEvent ) : void
		{
			callLater( showSlider );
		}
		
		private var sliderX   : Number;
		private var userInput : Boolean;
		
		private function showSlider() : void
		{
			if ( ! slider )
			{
				slider = new PopupVSlider();
				slider.minimum = Settings.MIN_BMP;
				slider.maximum = Settings.MAX_BPM;
				
				slider.liveDragging = true;
				slider.snapInterval = 1;
				slider.height = 160;
				slider.labels = [ slider.minimum, slider.maximum ];
				slider.tickValues = slider.labels;
				slider.showDataTip = false;
				
				slider.setStyle( 'dataTipPrecision' , 0 );
				//slider.setStyle( 'showTrackHighlight', true );
				
				slider.addEventListener( SliderEvent.CHANGE, onSliderChange );
				slider.addEventListener( SliderEvent.THUMB_PRESS, onSliderThumbPress );
				slider.addEventListener( SliderEvent.THUMB_RELEASE, onSliderThumbRelease );
				
				PopUpManager.addPopUp( slider, DisplayObject( parentApplication )  );
				slider.show();
				 
				slider.validateNow();
				slider.value = _bpm;
				sliderX = mouseX;
				moveSlider();
				
				stage.addEventListener( MouseEvent.CLICK, onStageClick, true, 1000 );
				stage.addEventListener( Event.RESIZE, onResize );
				
				digitsVisible( false );
				
				inputTempo = createDigit( true );
				inputTempo.text = _bpm.toString();
				inputTempo.maxChars = 3;
				inputTempo.restrict = "0-9";
				inputTempo.selectable = true;
				inputTempo.type = TextFieldType.INPUT;
				inputTempo.addEventListener( Event.CHANGE, onTextInput );
				inputTempo.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
				inputTempo.setSelection( 0, 3 );
				
				addChild( inputTempo );
				
				stage.focus = inputTempo;
				toolTip = null;
				
				invalidateDisplayList();
			}
		}
		
		private function onKeyDown( e : KeyboardEvent ) : void
		{
			var update : Boolean;
			
			if ( e.keyCode == Keyboard.ENTER )
			{
				exitFromEditTempo();
				return;
			}
			
			if ( e.keyCode == Keyboard.UP )
			{
				slider.value ++;
				update = true;
			}
			else if ( e.keyCode == Keyboard.DOWN )
			{
				slider.value --;
				update = true;
			}
				
		    if ( update )
			{
				bpm = slider.value;
				dispatchEvent( new Event( DisplayEvent.BPM_CHANGED ) );
			}
		}
		
		private function onTextInput( e : Event ) : void
		{
			userInput = true;
		}
		
		private function moveSlider() : void
		{
			var pos : Point = localToGlobal( new Point( sliderX, 0 ) );
			slider.move(  pos.x - ( slider.width + PopupVSlider._left + PopupVSlider._right ) / 2, pos.y - slider.height - PopupVSlider._bottom - 3 ); 
		}
		
		private function onResize( e : Event ) : void
		{
			moveSlider();
		}
		
		private function onStageClick( e : MouseEvent ) : void
		{
			if ( ! slider.hitTestPoint( e.stageX, e.stageY ) )
			{
				exitFromEditTempo();
			}
		}
		
		private function exitFromEditTempo() : void
		{
			if ( userInput )
			{
				var number : Number = parseInt( inputTempo.text );
				
				if ( ( number >= Settings.MIN_BMP ) && ( number <= Settings.MAX_BPM ) )
				{
					var event : ChangeBPMEvent = new ChangeBPMEvent( DisplayEvent.BPM_COMPLETE_CHANGE, number, bpm );
					
					bpm = number;
					dispatchEvent( new Event( DisplayEvent.BPM_CHANGED ) );
					dispatchEvent( event );
				}
				else
				{
					invalidateProperties();
				}
			}
			
			stage.removeEventListener( MouseEvent.CLICK, onStageClick, true );
			stage.removeEventListener( Event.RESIZE, onResize );
			slider.addEventListener( FlexEvent.HIDE, onSliderHide );
			slider.hide();
			
			inputTempo.removeEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
			inputTempo.removeEventListener( Event.CHANGE, onTextInput );
			removeChild( inputTempo );
			inputTempo = null;
			
			text = _bpm.toString();
			digitsVisible( true );
			
			stage.focus = null;
			setToolTip();
			
			userInput = false;
			invalidateDisplayList();
		}
		
		private function onSliderHide( e : FlexEvent ) : void
		{
			PopUpManager.removePopUp( slider );
			
			slider.removeEventListener( FlexEvent.HIDE, onSliderHide );
			slider.removeEventListener( SliderEvent.CHANGE, onSliderChange );
			slider.removeEventListener( SliderEvent.THUMB_PRESS, onSliderThumbPress );
			slider.removeEventListener( SliderEvent.THUMB_RELEASE, onSliderThumbRelease );
			
			slider = null;
		}
		
		private var thumbPressBPM : Number;
		
		private function onSliderThumbPress( e :SliderEvent ) : void
		{
			thumbPressBPM = _bpm;
		}
		
		private function onSliderThumbRelease( e : SliderEvent ) : void
		{
			dispatchEvent( new ChangeBPMEvent( DisplayEvent.BPM_COMPLETE_CHANGE, _bpm, thumbPressBPM ) );
		}
		
		private function onSliderChange( e : SliderEvent ) : void
		{
		  bpm = e.value;
		  userInput = false;
		  dispatchEvent( new Event( DisplayEvent.BPM_CHANGED ) );
		}
		
		private static const padding_left : Number = 0;
		private static const gap : Number = 4;
		
		override protected function commitProperties():void
		{
			if ( inputTempo )
			{
				inputTempo.text = _bpm.toString();
			}
			else
			{
				text = TimeUtils.formatValue( _bpm.toString(), 3 );
			}
			
			super.commitProperties();
			
			if ( inputTempo )
			{
				inputTempo.setSelection( 0, 3 );
			}
			else
			if ( onDigits.length > 0 )
			{
				onDigits[ 0 ].visible = _bpm >= 100;	
			}
		}
		
		override protected function measure():void
		{
			super.measure();
			
			measuredWidth += padding_left + + icon.width + gap;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			icon.y = ( unscaledHeight - icon.height ) / 2 + 2;
			icon.x = padding_left;
			
			var pos : Number = icon.x + icon.width + gap;
			
			if ( inputTempo )
			{
				var last  : TextField = offDigits[ offDigits.length - 1 ];
				var first : TextField = offDigits[ 0 ];
				
				inputTempo.x = pos;
				inputTempo.width = ( last.x + last.width ) - first.x;
			}
			else
			{
				var i : int = 0;
				var on  : TextField;
				var off : TextField;
				
				while( i < offDigits.length )
				{
					on  = onDigits[ i ];
					off = offDigits[ i ];
					
					off.x = pos;
					off.y = ( unscaledHeight - off.height ) / 2;
					
					on.x = pos;
					on.y = off.y;
					on.width = off.width;
					
					pos += off.width;
					
					i ++;
				}
			}
			
			//Прозрачный слой
			graphics.beginFill( 0xffffff, 0.0 );
			graphics.drawRect( 0, 0, unscaledWidth, unscaledHeight );
			graphics.endFill();
		}
	}
}