/**
 * Объединяет в себе группу управления дорожками секвенсора 
 */
package components.sequencer.controls
{
	import classes.Sequencer;
	import classes.SequencerImplementation;
	import classes.events.CategoryEvent;
	
	import com.audioengine.processors.Mixer;
	import com.utils.NumberUtils;
	
	import components.sequencer.ColorPalette;
	import components.sequencer.controls.events.HeaderContainerEvent;
	import components.sequencer.controls.events.TrackControlEvent;
	import components.sequencer.controls.events.TrackControlSwapEvent;
	import components.sequencer.timeline.Tracker;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.events.StateChangeEvent;
	import mx.managers.history.History;
	import mx.managers.history.HistoryOperation;
	import mx.managers.history.HistoryRecord;
	import mx.states.State;
	
	import spark.core.IViewport;
	
	public class TrackControlGroup extends UIComponent implements IViewport
	{
		private var _numTracks : int;
		//private var _numTracksChanged : Boolean;
		
		private var _vsp : Number = 0;
		
		/**
		 * Подсвеченный в данный момент контрол 
		 */		
		private var _highlighted : ControlContainer;
		
		/**
		 * Выбранный в данный момент контрол 
		 */		
		private var _selected : ControlContainer;
		
		private var _mixer : Mixer;
		private var _seq : SequencerImplementation;
		
		public function TrackControlGroup()
		{
			super();
			
			_seq = Sequencer.impl;
			_mixer = _seq.mixer;
			
			
			states = [ new State( { name : 'minimized' } ) , new State( { name : 'maximized' } ) ];
			currentState = 'minimized';
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
		}
		
		private function onAddedToStage( e : Event ) : void
		{
			_seq.addEventListener( CategoryEvent.CHANGE, onCategoryChange );
		}
		
		private function onRemovedFromStage( e : Event ) : void
		{
			_seq.removeEventListener( CategoryEvent.CHANGE, onCategoryChange );
		}
		
		private function onCategoryChange( e : CategoryEvent ) : void
		{
			getTrackControlAt( e.trackNumber ).category = e.category;
		}
		
		public function get numTracks() : int
		{
			return _numTracks;
		}
		
		/**
		 * Сдвигает номер трека всех семплов на offset, треков начиная c start трека
		 * @param offset
		 * 
		 */		
		private function shiftSamplesTrackNumber( start : int, offset : int = 1 ) : void
		{
			var i : int = 0;
			
			while( i < numChildren )
			{
				var s : TrackControl = TrackControl( getChildAt( i ) );
				
				if ( s.number > start )
				 {
						s.number += offset;
				 }	
					
				i ++;
			}	
		}
		
		/**
		 * Создает новый трек 
		 * @param index - позиция в которой вставить трек относительно других треков
		 * по умолчанию -1 - создать новый трек в самом конце 
		 * @param name - имя дорожки
		 * @param type - тип дорожки
		 * 
		 */		
		public function createTrackAt( index : int, name : String = null, type : String = null ) : void
		{
			if ( index < _numTracks )
			{
				shiftSamplesTrackNumber( index );	
			}
			
			addChildAt( createNewTrack( index, name, type ), index );
			
			_numTracks ++;
			invalidateSize();
		}
		
		/**
		 * Удаляет трек с указанным индексом 
		 * @param index - индекс трека который необходимо удалить
		 * 
		 */		
		public function removeTrackAt( index : int ) : void
		{
			if ( index < _numTracks )
			{
				shiftSamplesTrackNumber( index, -1 );
			}
			trace( 'removeTrackAt', index, _numTracks );
			var t : TrackControl = TrackControl( getChildAt( index ) );
			t.removeEventListener( StateChangeEvent.CURRENT_STATE_CHANGE, onStateChanging );
			
			t.removeEventListener( TrackControlEvent.SOLO_CHANGED, onSoloChanged );
			t.removeEventListener( TrackControlEvent.MONO_CHANGED, onMonoChanged );
			
			t.removeEventListener( TrackControlEvent.START_VOLUME_CHANGING, onStartVolumeChanging );
			t.removeEventListener( TrackControlEvent.VOLUME_CHANGING, onVolumeChanging );
			t.removeEventListener( TrackControlEvent.VOLUME_CHANGED, onVolumeChanged );
			
			t.removeEventListener( TrackControlEvent.START_PAN_CHANGING, onStartPanChanging );
			t.removeEventListener( TrackControlEvent.PAN_CHANGING, onPanChanging );
			t.removeEventListener( TrackControlEvent.PAN_CHANGED, onPanChanged );
			
			//t.removeEventListener( TrackControlEvent.START_NAME_CHANGING, onStartNameChanging );
			//t.removeEventListener( TrackControlEvent.NAME_CHANGED, onNameChanged );
			t.removeEventListener( FlexEvent.CREATION_COMPLETE, onTrackControlInitialized );
			
			removeChild( t );
			
			_numTracks --;
			invalidateSize();
		}	
		
		override protected function stateChanged(oldState:String, newState:String, recursive:Boolean):void
		{
			super.stateChanged( oldState, newState, recursive );
			
			if ( numChildren > 0 )
			{
				var t : TrackControl = getTrackControlAt( 0 );
				
				if ( t.currentState != newState )
				{
					var i : int = 0;
					
					while( i < numTracks )
					{
						t = getTrackControlAt( i );
						t.currentState = newState;
						
						i ++;
					}	
				}	
			}
		}
		
		/**
		 * Создает новую дорожку 
		 * @param trackNumber - номер дорожки
		 * @param name - имя дорожки
		 * @param type - тип дорожки
		 * @return экземпляер созданной дорожки
		 * 
		 */		
		private function createNewTrack( trackNumber : int, name : String = null, type : String = null ) : TrackControl
		{
			var t : TrackControl = new TrackControl();
			
			//t.trackName = name ? name : 'track ' + t.addDigits( trackNumber + 1 );
			t.number = trackNumber;
			t.color = ColorPalette.getColor( trackNumber );
			
			t.addEventListener( StateChangeEvent.CURRENT_STATE_CHANGE, onStateChanging );
			
			t.addEventListener( TrackControlEvent.SOLO_CHANGED, onSoloChanged );
			t.addEventListener( TrackControlEvent.MONO_CHANGED, onMonoChanged );
			
			t.addEventListener( TrackControlEvent.START_VOLUME_CHANGING, onStartVolumeChanging );
			t.addEventListener( TrackControlEvent.VOLUME_CHANGING, onVolumeChanging );
			t.addEventListener( TrackControlEvent.VOLUME_CHANGED, onVolumeChanged );
			
			t.addEventListener( TrackControlEvent.START_PAN_CHANGING, onStartPanChanging );
			t.addEventListener( TrackControlEvent.PAN_CHANGING, onPanChanging );
			t.addEventListener( TrackControlEvent.PAN_CHANGED, onPanChanged );
			
			//t.addEventListener( TrackControlEvent.START_NAME_CHANGING, onStartNameChanging );
			//t.addEventListener( TrackControlEvent.NAME_CHANGED, onNameChanged );
			t.addEventListener( FlexEvent.CREATION_COMPLETE, onTrackControlInitialized );
			
			t.currentState = currentState;
			
			return t;
		}
		
		private function onTrackControlInitialized( e : FlexEvent ) : void
		{
			updateControls( TrackControl( e.currentTarget ) );
		}
		
		private function updateControls( t : TrackControl ) : void
		{
			t.solo     = ( _mixer.soloChannel == t.number ) ? true : false;
			t.mono     = _mixer.getMonoAt( t.number );
			t.volume   = _mixer.getVolumeAt( t.number );
			t.pan      = _mixer.getPanAt( t.number );
			
			var soloChannel : int = _mixer.soloChannel;
			
			t.disabled = t.mono || ( ( soloChannel != -1 ) && ( soloChannel != t.number ) );
		}
		
		/**
		 * Обновляет положение всех регуляторов из модели данных 
		 * 
		 */		
		public function updateAllControls() : void
		{
			var i : int = 0;
			
			while( i < numChildren )
			{
				updateControls( TrackControl( getChildAt( i ) ) );
				
				i ++;
			}	
		}
		
		/**
		 * Возвращает дорожку с указанным индексом  
		 * @param index - номер дорожки
		 * @return - дорожка
		 * 
		 */		
		public function getTrackControlAt( index : int ) : TrackControl
		{
			return TrackControl( getChildAt( index ) );
		}	
		
		private var lastEvent : TrackControlEvent;
		
		private function onStartVolumeChanging( e : TrackControlEvent ) : void
		{
			lastEvent = e;
		}
		
		private function onVolumeChanging( e : TrackControlEvent, updateControl : Boolean = false ) : void
		{
			_mixer.setVolumeAt( e.number, e.volume );
			
			if ( updateControl )
			{
				TrackControl( getChildAt( e.number ) ).volume = e.volume;
			}	
		}
		
		private function onVolumeChanged( e : TrackControlEvent ) : void
		{
		  if ( lastEvent.volume != e.volume )
		  {
			  var trackNumber : String = ( e.number + 1 ).toString();
			  
			  History.add( new HistoryRecord( new HistoryOperation( this, onVolumeChanging, lastEvent, true ), new HistoryOperation( this, onVolumeChanging, e, true ),
			                                  'Отменить изменение громкости дорожки ' + trackNumber, 
											  'Изменить громкость дорожки ' + trackNumber + ' на ' + NumberUtils.valueToPercent( e.volume, Settings.MAX_TRACK_SOUND_VOLUME ).toString() + '%'
			              ) );
		  }	  
		}	
		
		private function onStartPanChanging( e : TrackControlEvent ) : void
		{
			lastEvent = e;
		}
		
		private function onPanChanging( e : TrackControlEvent, updateControl : Boolean = false ) : void
		{
			_mixer.setPanAt( e.number, e.pan );
			
			if ( updateControl )
			{
				TrackControl( getChildAt( e.number ) ).pan = e.pan;
			}
		}
		
		private function onPanChanged( e : TrackControlEvent ) : void
		{
			if ( lastEvent.pan != e.pan )
			{
				var trackNumber : String = ( e.number + 1 ).toString();
				
				History.add( new HistoryRecord( new HistoryOperation( this, onPanChanging, lastEvent, true ), new HistoryOperation( this, onPanChanging, e, true ),
				             'Отменить изменение панорамы дорожки ' + trackNumber, 'Изменить панораму дорожки на' + trackNumber + '\n' + SoundPanKnob.getFormatedValue( e.pan )
				) );	
			}
		}
		
		private function onMonoChanged( e : TrackControlEvent, addToHistory : Boolean = true, updateControl : Boolean = false ) : void
		{
			_mixer.setMonoAt( e.number, e.mono );
			
			var t : TrackControl = TrackControl( getChildAt( e.number ) );
			
			if ( _mixer.soloChannel == -1 )
			{
				t.disabled = e.mono;
			}
			
			dispatchEvent( new Event( Event.CHANGE ) );
			
			if ( updateControl )
			{
				t.mono = e.mono;
			}	
			
			if ( addToHistory )
			{
				var backName : String;
				var forwardName : String;
				var trackNumber : String = ( e.number + 1 ).toString();
				
				if ( e.mono )
				{
					backName    = 'Отменить включение режима "моно" для дорожки ' + trackNumber;
					forwardName = 'Включить режим "моно" для дорожки ' + trackNumber; 
				}
				else
				{
					backName    = 'Отменить отключение режима "моно" для дорожки ' + trackNumber;
					forwardName = 'Отключить режим "моно" для дорожки ' + trackNumber;
				}
				
				History.add( new HistoryRecord( new HistoryOperation( this, onMonoChanged, new TrackControlEvent( e.type, e.number, e.name, ! e.mono, e.solo, e.volume, e.pan ), false, true ),
					                            new HistoryOperation( this, onMonoChanged, e, false, true ), backName, forwardName
				                                 
				) ); 
			}	
		}	
		
		private function onSoloChanged( e : TrackControlEvent, addToHistory : Boolean = true, updateControl : Boolean = false ) : void
		{
			var backSolo  : Boolean = ! e.solo;
			var backTrack : int     = e.number;
			
			if ( e.solo )
			{
				backTrack = _mixer.soloChannel == -1 ? e.number : _mixer.soloChannel;
				backSolo  = _mixer.soloChannel != -1; 
			}
			  
			_mixer.soloChannel = e.solo ? e.number : -1;
			
			var i : int = 0;
			var source : TrackControl = TrackControl( getChildAt( e.number ) );
			
			while( i < numChildren )
			{
				var t : TrackControl = TrackControl( getChildAt( i ) );
				
				if ( source != t )
				{
					t.solo = false;
					t.disabled = t.mono || e.solo;
				}
				else
				{
					if ( e.solo )
					{
						t.disabled = false;
					}
					else
					{
						t.disabled = t.mono;
					}	
				}	
				
				i ++;
			}
			
			dispatchEvent( new Event( Event.CHANGE ) );
			
			if ( updateControl )
			{
				source.solo = e.solo;
			}	
			
			if ( addToHistory )
			{
				var backName : String;
				var forwardName : String;
				var trackNumber : String = ( e.number + 1 ).toString();
				
				if ( e.solo )
				{
					backName    = 'Отменить включение режима "соло" для дорожки ' + trackNumber;
					forwardName = 'Включить режим "соло" для дорожки ' + trackNumber; 
				}
				else
				{
					backName    = 'Отменить отключение режима "соло" для дорожки ' + trackNumber;
					forwardName = 'Отключить режим "соло" для дорожки ' + trackNumber;
				}
				
				History.add( new HistoryRecord( new HistoryOperation( this, onSoloChanged, new TrackControlEvent( e.type, backTrack, e.name, e.mono, backSolo, e.volume, e.pan ), false, true ),
					new HistoryOperation( this, onSoloChanged, e, false, true ), backName, forwardName
				    
				) ); 
			}
		}
		
		/*
		private function onStartNameChanging( e : TrackControlEvent ) : void
		{
			backOp = new HistoryOperation( 'Track ' + e.number + ' change name to ' + e.name, this, onNameChanged, e, true );
		}
		
		private function onNameChanged( e : TrackControlEvent, updateControls : Boolean = false ) : void
		{
			if ( updateControls )
			{
				TrackControl( getChildAt( e.number ) ).trackName = e.name;
				return;
			}	
			
			History.add( new HistoryRecord( backOp, new HistoryOperation( 'Track ' + e.number + ' change name to ' + e.name, this, onNameChanged, e, true ) ) );
		}
		*/
		public function swap( index1 : int, index2 : int ) : void
		{
			var c1 : TrackControl = TrackControl( getChildAt( index1 ) );
			var c2 : TrackControl = TrackControl( getChildAt( index2 ) );
			
			c1.number = index2;
			c2.number = index1;
			c1.color  = ColorPalette.getColor( c1.number );
			c2.color  = ColorPalette.getColor( c2.number );
			
			//c1.updateControls();
			//c2.updateControls();
			
			swapChildren( c1, c2 );
			invalidateDisplayList();
		}
		
		public function moveTracks( from : int, to : int ) : void
		{
			var c : TrackControl = TrackControl( getChildAt( from ) );
			    c.number = to;
				c.color  = ColorPalette.getColor( c.number );
				//c.updateControls();
				
			setChildIndex( c, to );
			
			//Сдвигаем номера всех дорожек вверх или вниз
			var op      : Boolean = from < to;
			var posFrom : int = op ? from : to + 1; 
			var posTo   : int = op ? to - 1 : from;  
			var inc     : int = op ? -1 : 1;
			var i       : int = posFrom;
			
			while( i <= posTo )
			{
				c         = TrackControl( getChildAt( i ) );
				c.number += inc;
				c.color   = ColorPalette.getColor( c.number );
				//c.updateControls();
				
				i ++;
			}
			
			invalidateDisplayList();
		}	
		
		private function onStateChanging( e : StateChangeEvent ) : void
		{
			var i : int = 0;
			
			while( i < numChildren )
			{
				var t : UIComponent = UIComponent( getChildAt( i ) );
				
				if ( t != e.currentTarget )
				{
					t.currentState = e.newState;
				}	
				
				i ++;
			}
			
			currentState = e.newState;
		}	
		/*
		private function removeTracks( count : int ) : void
		{
			var i : int = 0;
			
			while( i < count )
			{
				removeChildAt( numChildren - 1 );
				i ++;
			}	
		}
		*/
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			/*if ( _numTracksChanged )
			{
				populateTracks( _numTracks );
				_numTracksChanged = false;
				invalidateSize();
				invalidateDisplayList();
			}*/	
		}
		
		override protected function measure() : void
		{
			super.measure();
			
			var w : Number = 0;
			var h : Number = 0;
			
			if ( numChildren > 0 )
			{
				var i : int = 0;
				var t : UIComponent;
				
				while( i < numChildren )
				{
					t = UIComponent( getChildAt( i ) );
					h += t.getExplicitOrMeasuredHeight();    
					
					i ++;
				}
				
				w = t.getExplicitOrMeasuredWidth();
			}
			
			measuredWidth = w;
			measuredHeight = h;
		}	
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			
				var i : int = 0;
				var y : Number = 0;
				
				while ( i < numChildren )
				{
					var t : UIComponent = UIComponent( getChildAt( i ) ); 
					t.setActualSize( t.getExplicitOrMeasuredWidth(), t.getExplicitOrMeasuredHeight() );
					t.move( 0, y );
					
					y += t.height;
					i ++;
				}
				
			scrollRect = new Rectangle( 0, _vsp, unscaledWidth, unscaledHeight );	
		}
		
		/**
		 * Подсввечивает указанную дорожку 
		 * @param number
		 * 
		 */		
		public function highlight( number : int ) : void
		{
			if ( _numTracks == 0 ) return;
			if ( _highlighted && number == _highlighted.number ) return;
			
			if ( _highlighted )
			{
				_highlighted.hovered = false;
				_highlighted = null;
			}	
			
			if ( number > -1 )
			{
				var t : ControlContainer = ControlContainer( getChildAt( number ) );
				t.hovered = true;
				
				_highlighted = t;
			}		
		}
		
		/**
		 * Выбирает указанную дорожку 
		 * @param number
		 * 
		 */		
		public function select( number : int ) : void
		{
			if ( _numTracks == 0 ) return;
			if ( _selected && number == _selected.number ) return;
			
			if ( _selected )
			{
				_selected.selected = false;
				_selected = null;
			}	
			
			if ( number > -1 )
			{
				var t : ControlContainer = ControlContainer( getChildAt( number ) );
				t.selected = true;
				
				_selected = t;
			}		
		}
		
		/**
		 * 
		 * Реализация IViewport
		 * 
		 */		
		
		public function get clipAndEnableScrolling() : Boolean
		{
			return true;
		}	
		
		public function set clipAndEnableScrolling( value : Boolean ) : void
		{
		}
		
		public function get contentHeight() : Number
		{
			return getExplicitOrMeasuredHeight();
		}
		
		public function get contentWidth() : Number
		{
			return getExplicitOrMeasuredWidth();
		}
		
		public function get horizontalScrollPosition():Number
		{
			return 0;	
		}
		
		public function set horizontalScrollPosition(value:Number):void
		{
		}
		
		public function get verticalScrollPosition() : Number
		{
			return _vsp;
		}
		
		public function set verticalScrollPosition( value : Number ) : void
		{
			_vsp = value;
			//dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, "verticalScrollPosition", value, value ) );
			invalidateDisplayList();
		}
		
		public function getHorizontalScrollPositionDelta( navigationUnit : uint ) : Number
		{
			return 0;
		}
		
		public function getVerticalScrollPositionDelta(navigationUnit:uint):Number
		{
			return 0;
		}	
	}
}