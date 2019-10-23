package components.sequencer.controls
{
	import components.sequencer.controls.events.HeaderContainerEvent;
	import components.sequencer.controls.events.TrackControlEvent;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	import mx.events.SliderEvent;
	import mx.states.State;

	public class TrackControl extends ControlContainer
	{
		private var _pan : SoundPanKnob;
		
		private var _volume : VolumeControl;
		
		private var _mono : Button;
		
		private var _solo : Button;
		
		private var _icon : CategoryIcon;
		
		//анимационный tween
		private var _tween : Tween;
		//Время раскрытия скрытия
		private var _time  : int = 250;
		
		public function TrackControl()
		{
			super();
			
			states = [ new State( { name : 'minimized' } ) , new State( { name : 'maximized' } ) ];
			currentState = 'maximized';
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_mono = new Button();
			_mono.label = 'M';
			_mono.toolTip = 'Отключить дорожку';
			_mono.toggle = true;
			_mono.tabEnabled = false;
			_mono.focusEnabled = false;
			_mono.setStyle( 'paddingTop', 0 );
			_mono.setStyle( 'paddingBottom', 0 );
			_mono.setStyle( 'paddingLeft', 0 );
			_mono.setStyle( 'paddingRight', 0 );
			_mono.setStyle( 'toolTipPlacement', 'errorTipRight' );
			_mono.addEventListener( MouseEvent.CLICK, onMonoClick );
			
			_solo = new Button();
			_solo.label = 'С';
			_solo.toolTip = 'Отключить все дорожки, кроме этой';
			_solo.toggle = true;
			_solo.tabEnabled = false;
			_solo.focusEnabled = false;
			_solo.setStyle( 'paddingTop', 0 );
			_solo.setStyle( 'paddingBottom', 0 );
			_solo.setStyle( 'paddingLeft', 0 );
			_solo.setStyle( 'paddingRight', 0 );
			_solo.setStyle( 'toolTipPlacement', 'errorTipRight' );
			_solo.addEventListener( MouseEvent.CLICK, onSoloClick );
			
			_pan = new SoundPanKnob();
			_pan.tabEnabled = false;
			_pan.focusEnabled = false;
			_pan.addEventListener( SliderEvent.CHANGE, onPanChanged );
			_pan.addEventListener( SliderEvent.THUMB_PRESS, onPanPress );
			_pan.addEventListener( SliderEvent.THUMB_RELEASE, onPanRelease );
			
			_volume = new VolumeControl();
			_volume.addEventListener( SliderEvent.CHANGE, onVolumeChanged );
			_volume.addEventListener( SliderEvent.THUMB_PRESS, onVolumePress );
			_volume.addEventListener( SliderEvent.THUMB_RELEASE, onVolumeRelease );
			
			_icon = new CategoryIcon();
			
			addEventListener( HeaderContainerEvent.START_CHANGING, onStartNameChanging );
			addEventListener( HeaderContainerEvent.CHANGED, onNameChanged );
			
			addChild( _mono );
			addChild( _solo );
			addChild( _pan );
			addChild( _volume );
			addChild( _icon );
			
			swapChildren( _icon, _header );
			
			_page.addEventListener( MouseEvent.CLICK, onPageClick );
			
			if ( currentState == 'maximized' )
			{
				setMaximizeState();
			}
			else
			{
				setMinimizeState();
			}	
				
		}
		
		private function onStartNameChanging( e : HeaderContainerEvent ) : void
		{	
			sendEvent( TrackControlEvent.START_NAME_CHANGING );
		}
		
		private function onNameChanged( e : HeaderContainerEvent ) : void
		{
			sendEvent( TrackControlEvent.NAME_CHANGED );
		}	
		
		public function get mono() : Boolean
		{
			return _mono.selected;
		}
		
		public function set mono( value : Boolean ) : void
		{
			_mono.selected = value;
		}
		
		public function get category() : String
		{
			return _icon.category;
		}
		
		public function set category( value : String ) : void
		{
			_icon.category = value;
			
			var cd : Object = Settings.getCategoryDescription( value );
			
			if ( cd.id )
			{
				trackName = cd.short;
			}
			else
			{
				trackName = '';
			}
			
			invalidateDisplayList();
		}
		
		public function get solo() : Boolean
		{
			return _solo.selected;
		}
		
		public function set solo( value : Boolean ) : void
		{
			_solo.selected = value;
		}
		
		public function get volume() : Number
		{
			return _volume.value;
		}
		
		public function set volume( value : Number ) : void
		{
			_volume.value = value;
		}
		
		public function get pan() : Number
		{
			return _pan.value;
		}
		
		public function set pan( value : Number ) : void
		{
			_pan.value = value;
		}	
		
		private function sendEvent( type : String ) : void
		{	
			dispatchEvent( new TrackControlEvent( type, _number, trackName, _mono.selected, _solo.selected, _volume.value, _pan.value ) );	
		}
		
		private function onVolumePress( e : Event ) : void
		{
			sendEvent( TrackControlEvent.START_VOLUME_CHANGING );
		}	
		
		private function onVolumeRelease( e : Event ) : void
		{
			sendEvent( TrackControlEvent.VOLUME_CHANGED );
		}	
		
		private function onVolumeChanged( e : SliderEvent ) : void
		{
			sendEvent( TrackControlEvent.VOLUME_CHANGING );
		}	
		
		private function onPanPress( e : SliderEvent ) : void
		{
			sendEvent( TrackControlEvent.START_PAN_CHANGING );	
		}	
		
		private function onPanRelease( e : SliderEvent ) : void
		{
			sendEvent( TrackControlEvent.PAN_CHANGED );
		}	
		
		private function onPanChanged( e : SliderEvent ) : void
		{
			sendEvent( TrackControlEvent.PAN_CHANGING );	
		}	
		
		private function onMonoClick( e : MouseEvent ) : void
		{
			/*_mixer.setMonoAt( _number, _mono.selected );
			
			if ( _mixer.soloChannel == -1 )
			{
				disabled = _mono.selected;
			}
			*/
			
			sendEvent( TrackControlEvent.MONO_CHANGED );
		}
		
		private function onSoloClick( e : MouseEvent ) : void
		{
			//_mixer.setSoloAt( _number, _solo.selected );
			sendEvent( TrackControlEvent.SOLO_CHANGED );
		}	
		
		private function onPageClick( e : MouseEvent ) : void
		{
		  if ( currentState == 'maximized' )
		  {
			  currentState = 'minimized';
		  }
		  else
		  {
			  currentState = 'maximized';
		  }	  
		}	
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			unscaledWidth -= currentState == 'maximized' ?  _page.getMinimizedWidth() : _page.getMaximizedWidth();
			
			if ( currentState == 'maximized' )
			{
				_pan.setActualSize( _pan.getExplicitOrMeasuredWidth(), _pan.getExplicitOrMeasuredHeight() );
				_pan.move( 14, 8 );
				
				_volume.setActualSize( work_area_width - 6, _volume.getExplicitOrMeasuredHeight() );
				_volume.move( ( work_area_width - _volume.width ) / 2 - 1, unscaledHeight - _volume.height - 7 );
				
				_mono.setActualSize( 20, 20 );
				_solo.setActualSize( 20, 20 );
				
				_solo.move( work_area_width - _solo.width - 2, 2 );
				_mono.move( work_area_width - _mono.width - 2, _mono.height + _solo.y + 1 );
			}
			else
			{
				_icon.setActualSize( _icon.measuredWidth, _icon.measuredHeight );
				_icon.x = ( work_area_width - _icon.width ) / 2;
				_icon.y = ( unscaledHeight - _icon.height ) / 2;
			}
		}
		
		private static const work_area_maximized_width : Number = 90;
		private static const work_area_minimized_width : Number = 60;
		private var work_area_width : Number;
		
		private function getMaximizedWidth() : Number
		{
			return work_area_maximized_width + _page.getMinimizedWidth();
		}
		
		private function getMinimizedWidth() : Number
		{
			return work_area_minimized_width + _page.getMaximizedWidth();	
		}
		
		private function setMinimizeState() : void
		{
			_pan.visible = false;
			_volume.visible = false;
			_mono.visible = false;
			_solo.visible = false;
			_icon.visible = true;
			//_header.visible = false;
		}
		
		private function setMaximizeState() : void
		{
			_pan.visible = true;
			_volume.visible = true;
			_mono.visible = true;
			_solo.visible = true;
			_icon.visible = false;
			//_header.visible = true;
		}	
		
		override protected function measure():void
		{
			super.measure();
			
			if ( currentState == 'maximized' )
			{
				measuredWidth = getMaximizedWidth();
				work_area_width = work_area_maximized_width;
			}
			else
			{
				measuredWidth = getMinimizedWidth();
				work_area_width = work_area_minimized_width;
			}	
		}
		
		override protected function stateChanged(oldState:String, newState:String, recursive:Boolean):void
		{
			super.stateChanged( oldState, newState, recursive );
			
			if ( initialized )
			{
				//_page.currentState = oldState;
				
				if ( newState == 'maximized' )
				{
					setTween( getExplicitOrMeasuredWidth(), getMaximizedWidth(), _time );
				}
				else
				{
					setMinimizeState();
					setTween( getExplicitOrMeasuredWidth(), getMinimizedWidth(), _time );
				}
			}		
		}
		
		private function setTween( startValue : Number, endValue : Number, duration : Number, easingFunction : Function = null ) : void
		{
			_tween = new Tween( this, startValue, endValue, duration );
			if ( easingFunction != null )
				_tween.easingFunction = easingFunction;
		}
		
		mx_internal function onTweenUpdate(value:Number):void
		{
			explicitWidth = value;
		}
		
		mx_internal function onTweenEnd( value:Number ) : void
		{
			if ( currentState == 'maximized' )
			{
				setMaximizeState();
				_page.currentState = 'minimized';
			}
			else
			{
				_page.currentState = 'maximized';
			}	
				
			explicitWidth = NaN;
			_tween = null;
			invalidateSize();
		}
	}
}