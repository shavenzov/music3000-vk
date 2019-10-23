package classes
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.Driver;
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.IProcessor;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.core.events.DriverEvent;
	import com.audioengine.devices.AudioInput;
	import com.audioengine.processors.Combiner;
	import com.audioengine.processors.Mixer;
	import com.audioengine.sequencer.AudioLoop;
	import com.audioengine.sequencer.ListNote;
	import com.audioengine.sequencer.Note;
	import com.audioengine.sequencer.Sequencer;
	import com.audioengine.sequencer.events.SequencerEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.utils.ByteArray;
	
	import mx.managers.history.History;
	import mx.managers.history.HistoryOperation;
	import mx.managers.history.HistoryRecord;
	
	import classes.events.CategoryEvent;
	import classes.events.ChangeBPMEvent;
	import classes.events.SequencerEventPositionChangedBy;

	public class SequencerImplementation extends EventDispatcher
	{
		/**
		 * Список треков секвенсора 
		 */		
		private var _channels : Vector.<com.audioengine.sequencer.Sequencer> = new Vector.<com.audioengine.sequencer.Sequencer>();
		
		/**
		 *Управление микшером 
		 * 
		 */
		private var _mixer : Mixer = new Mixer();
		
		/**
		 * Устройство воспроизведения 
		 */		
		private const _driver : Driver = new Driver();
		
		/**
		 *Палитра семплов секвенсора 
		 * 
		 */
		private var _palette : SamplesPalette;
		
		/**
		 * Идет сейчас воспроизведение или нет 
		 */		
		private var _playing : Boolean;
		
		/**
		 * Идет процесс записи 
		 */		
		private var _recording : Boolean;
		
		/**
		 * Идет процесс импорта музыки в поток данных 
		 */		
		private var _mixdown : Boolean;
		
		/**
		 * Текущее положение курсора воспроизведения 
		 */		
		private var _position : Number = 0.0;
		
			
		private var _startPosition : Number;
		
		private var _endPosition : Number;
		
		/**
		 * Длина всех дорожек 
		 */		
		private var _duration : Number = 0.0;
		
		/**
		 * Позиция окончания музыки 
		 */		
		private var _realEnd : Number = 0.0;
		
		/**
		 * Позиция начала музыки 
		 */		
		private var _realStart : Number = 0.0;
		
		/**
		 * Вкл\выкл зацикленное воспроизведение 
		 */		
		private var _loop : Boolean;
		
		/**
		 * Захват позиции 
		 */		
		private var _captured : Boolean;
		
		/**
		 * Определяет будет ли воспроизведение слева направо или справо налево 
		 */		
		private var _inverse : Boolean;
		
		private var _positionAfterProcessing : Number;
		private var _eventAfterProcessing : SequencerEvent;
		
		/**
		 * Скорость воспроизведения секвенсора 
		 */		
		private var _bpm : Number;
		
		/**
		 * Игнорировать изменения 
		 */		
		private var _ignoreChanges : Boolean;
		
		public function SequencerImplementation()
		{
		    super();
			init();
		}
		
		public function get ignoreChanges() : Boolean
		{
			return _ignoreChanges;
		}
		
		public function set ignoreChanges( value : Boolean ) : void
		{
			if ( value != _ignoreChanges )
			{
				_ignoreChanges = value;
				
				var i : int = 0; 
				
				for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
				{
					channel.listNote.ignoreChanges = _ignoreChanges;
					calculateCategory( i );
					i ++;
				}
				
				mixer.ignoreChanges = _ignoreChanges;
				palette.ignoreChanges = _ignoreChanges;
			}
		}
		
		/**
		 *Инициализирует секвенсор 
		 */
		private function init() : void
		{
			//Создаем библиотеку семплов секвенсора
			_palette = new SamplesPalette();
			
			_driver.input = _mixer;
			_driver.addEventListener( DriverEvent.BEFORE_PROCESSING, beforeProcessing )
			_driver.addEventListener( DriverEvent.AFTER_PROCESSING, afterProcessing );
			
			_mixer.addEventListener( SequencerEvent.MIXER_PARAM_CHANGED, onMixerParamChanged );
		}
		
		private function onMixerParamChanged( e : SequencerEvent ) : void
		{
			dispatchEvent( e );
		}
		
		private function beforeProcessing( e : DriverEvent ) : void
		{
			if ( ! isNaN( _positionAfterProcessing ) )
			{
				position = _positionAfterProcessing;
				_positionAfterProcessing = NaN;
			}
			
			if ( _eventAfterProcessing )
			{
				dispatchEvent( _eventAfterProcessing );
				_eventAfterProcessing = null;
			}
		}
		
		private function afterProcessing( e : DriverEvent ) : void
		{
			updatePosition();
		}
		
		private function updatePosition() : void
		{
			if ( _channels.length > 0 )
			{
				_position = _channels[ 0 ].position;
			}
			
			dispatchEvent( new SequencerEvent( SequencerEvent.POSITION_CHANGED, _position ) );
		}	
		
		public function get numChannels() : int
		{
		  return _channels.length;
		}	
		
		/**
		 * Необходимо вызывать при изменениях связанных с семплами 
		 * 
		 */		
		public function update() : void
		{
			calculateRealParams();
		}
		
		public function get realEnd() : Number
		{
			return _realEnd;
		}
		
		public function get realStart() : Number
		{
			return _realStart;
		}
		
		/**
		 * Возвращает длину музыки 
		 * @return 
		 * 
		 */		
		public function get realDuration() : Number
		{
		  return _realEnd - _realStart;
		}
		
		/**
		 * Вычисляет реальную длину звучания музыки 
		 * 
		 */		
		private function calculateRealParams() : void
		{
			_realEnd   = 0.0;
			_realStart = Number.MAX_VALUE;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
			  if ( channel.realEnd > 0.0 )
			  {
				  _realEnd   = Math.max( _realEnd, channel.realEnd );
				  _realStart = Math.min( _realStart, channel.realStart ); 
			  }  	
			}
			
			if ( _realStart == Number.MAX_VALUE )
			{
				_realStart = 0.0;
			}
		}
		
		private function onNoteChanged( e : SequencerEvent ) : void
		{
			calculateRealParams();
			dispatchEvent( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE, _position ) );
		}	
		
		private function setListenersForSEQ( seq : com.audioengine.sequencer.Sequencer ) : void
		{
			seq.addEventListener( SequencerEvent.END, onEnd );
			seq.addEventListener( SequencerEvent.END_LOOP, onEndLoop );
		}
		
		private function removeListenersForSEQ( seq : com.audioengine.sequencer.Sequencer ) : void
		{
			seq.removeEventListener( SequencerEvent.END, onEnd );
			seq.removeEventListener( SequencerEvent.END_LOOP, onEndLoop );
		}
		
		private function onEnd( e : SequencerEvent ) : void
		{
			if ( ! _loop )
			{
				stop();
				_positionAfterProcessing = inverse ? duration : 0;
			}	
				
			_eventAfterProcessing = e;
		}
		
		private function onEndLoop( e : SequencerEvent ) : void
		{
			_eventAfterProcessing = e;
		}
		
		private function onEndMusic( e : SequencerEvent ) : void
		{
			if ( _recording ) return;
			if ( _eventAfterProcessing ) return;
			
			if ( e.pos >= _realEnd )
			{
				if ( ! _loop )
				{
					stop();
					_positionAfterProcessing = inverse ? duration : 0;
				}
				
				_eventAfterProcessing = e;	
			}	
		}	
		
		public function sendCommand( e : Event ) : void
		{
			dispatchEvent( e );
		}	
		
		/**
		 * Меняет две дорожки местами
		 * @param index1
		 * @param index2
		 * 
		 */		
		public function swapChannels( index1 : int, index2 : int ) : void
		{
			var buf : com.audioengine.sequencer.Sequencer = _channels[ index1 ];
			_channels[ index1 ] = _channels[ index2 ];
			_channels[ index2 ] = buf;
			
			_mixer.swapChannels( index1, index2 );
			dispatchEvent( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE, _position ) );
		}
		
		/**
		 * Перемещает дорожку fromIndex на toIndex, смещая вверх все остальные 
		 * @param fromIndex
		 * @param toIndex
		 * 
		 */		
		public function moveChannels( fromIndex : int, toIndex : int ) : void
		{
			var c : Vector.<com.audioengine.sequencer.Sequencer> = _channels.splice( fromIndex, 1 );
			_channels.splice( toIndex, 0, c[ 0 ] );
			
			_mixer.moveChannels( fromIndex, toIndex );
			dispatchEvent( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE, _position ) );
		}	
		
		/**
		 * Создает подканал в указаном канале 
		 * @param index
		 * 
		 */		
		public function createSubChannelAt( index : int ) : void
		{	
			var subChannel : Combiner = new Combiner();
			    subChannel.add( _channels[ index ] );
				
			_mixer.inputs[ index ] = subChannel;
		}
		
		/**
		 * Удаляет подканал в указанном канале 
		 * @param index
		 * 
		 */		
		public function removeSubChannelAt( index : int ) : void
		{
			_mixer.inputs[ index ] = _channels[ index ];
		}
		
		/**
		 * Добавляет устройство в подканал 
		 * @param index
		 * @param device
		 * 
		 */		
		public function addToSubChannel( index : int, device : IProcessor ) : void
		{
			Combiner( _mixer.inputs[ index ] ).add( device );
		}
		
		/**
		 * Удаляет устройство из подканала 
		 * @param index
		 * @param device
		 * 
		 */		
		public function removeFromSubChannel( index : int, device : IProcessor ) : void
		{
			Combiner( _mixer.inputs[ index ] ).remove( device );
		}	
		
		/**
		 * Создает новую дорожку в указанной позиции 
		 * @param index
		 * 
		 */		
		public function createChannelAt( index : int = -1 ) : void
		{
			var seq : com.audioengine.sequencer.Sequencer = new com.audioengine.sequencer.Sequencer();
			seq.listNote = new ListNote();
			seq.listNote.addEventListener( SequencerEvent.SAMPLE_CHANGE, onNoteChanged );
			
			seq.bpm = _bpm;
			seq.startPosition = _startPosition;
			seq.endPosition = _endPosition;
			seq.duration = _duration;
			seq.position = _position;
			seq.loop     = _loop;
			seq.inverse  = _inverse;
			seq.addEventListener( SequencerEvent.END_MUSIC, onEndMusic );
			
			_mixer.add( seq, index );
			
			if ( index == -1 )
			{
				index = _channels.length;
			}	
			
			if ( index == 0 )
			{
				setListenersForSEQ( seq );
				_channels.push( seq );
			}
			else
			{
				_channels.splice( index, 0, seq );
			}
		}
		
		/**
		 * Удаляет дорожку секвенсора с указанным номером 
		 * @param trackNumber - Номер дорожки секвенсора для удаления
		 * 
		 */		
		public function removeChannelAt( channelNumber : int = -1 ) : void
		{	
			_mixer.remove( channelNumber );
			
			if ( channelNumber == -1 )
			{
				channelNumber = _channels.length - 1;
			}	
			
			if ( channelNumber == 0 )
			{
				removeListenersForSEQ( _channels[ 0 ] );
				
				if ( _channels.length > 1 )
				{
					setListenersForSEQ( _channels[ 1 ] );
				}	
			}	
			
			_channels[ channelNumber ].listNote.removeEventListener( SequencerEvent.SAMPLE_CHANGE, onNoteChanged );
			_channels[ channelNumber ].removeEventListener( SequencerEvent.END_MUSIC, onEndMusic );
			_channels.splice( channelNumber, 1 );
		}
		
		public function removeAllChannels() : void
		{	
			_mixer.soloChannel = -1;
			
			while( _channels.length > 0 )
			 removeChannelAt();	
		}
		
		/**
		 * Возвращает дорожку с указанным индексом 
		 * @param trackNumber - номер дорожки
		 * @return - указатель на дорожку
		 * 
		 */		
		public function getChannelAt( channelNumber : int ) : com.audioengine.sequencer.Sequencer
		{
			return _channels[ channelNumber ];
		}	
		
		/**
		 * 
		 * Доступ к экземпляру Mixer Для работы с каналами
		 * 
		 */		
		public function get mixer() : Mixer
		{
			return _mixer;
		}	
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
			_duration = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.duration = value;
			}
			
			dispatchEvent( new SequencerEvent( SequencerEvent.DURATION_CHANGED ) );
		}
		
		public function get timeDuration() : Number
		{
			return TimeConversion.numSamplesToSeconds( _duration );
		}
		
		public function set timeDuration( value : Number ) : void
		{
			duration = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get defaultStartPosition() : Number
		{
			return _channels.length > 0 ? _channels[ 0 ].startPosition : _startPosition;
		}
		
		public function get defaultEndPosition() : Number
		{
			return _channels.length > 0 ? _channels[ 0 ].endPosition : _endPosition;
		}	
		
		public function get startPosition() : Number
		{
			return _startPosition;
		}
		
		public function set startPosition( value : Number ) : void
		{
			_startPosition = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.startPosition = value;
			}
			
			dispatchEvent( new SequencerEvent( SequencerEvent.LOOP_CHANGED ) );
		}
		
		public function get endPosition() : Number
		{
			return _endPosition;
		}
		
		public function set endPosition( value : Number ) : void
		{
			_endPosition = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.endPosition = value;
			}
			
			dispatchEvent( new SequencerEvent( SequencerEvent.LOOP_CHANGED ) );
		}	
		
		public function get loop() : Boolean
		{
			return _loop;
		}
		
		public function set loop( value : Boolean ) : void
		{
			if ( value == _loop )
			{
				return;
			}	
			
			if ( _startPosition == _endPosition )
			{
				if ( _numSamples == 0 )
				{
					startPosition = 0;
				    endPosition = TimeConversion.barsToNumSamples( 4, _bpm );
				}
				else
				{
					startPosition = _realStart;
					endPosition   = _realEnd;	
				}
			}
			
			_loop = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.loop = value;
			}
			
			dispatchEvent( new SequencerEvent( SequencerEvent.LOOP_CHANGED ) );
		}	
		
		/**
		 *Текущее положение воспроизведения в фреймах
		 * 
		 */
		public function get position() : Number
		{
			return _position;
		}
		
		public function set position( value : Number ) : void
		{
			if ( value < 0 ) value = 0;
			else if ( value > _duration ) value = _duration;	
			
			if ( value != _position )
			{
				_position = value;
				
				for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
				{
					channel.position = value;
				}
				
				dispatchEvent( new SequencerEvent( SequencerEvent.POSITION_CHANGED, _position, SequencerEventPositionChangedBy.GUI ) );
			}
		}
		
		public function get timePosition() : Number
		{
			return TimeConversion.numSamplesToSeconds( _position );
		}
		
		public function set timePosition( value : Number ) : void
		{
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.position = TimeConversion.secondsToNumSamples( value );
			}
		}	
			
		/**
		 * Воспроизводить ли данные справа на лево
		 */	
		public function get inverse() : Boolean
		{	
			return _inverse;
		}
		
		public function set inverse( value : Boolean ) : void
		{
			_inverse = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.inverse = value;
			}
		}
		
		public function get captured() : Boolean
		{
			return _captured;
		}
		
		public function set captured( value : Boolean ) : void
		{
			_captured = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.captured = value;
			}
		}	
		
		/**
		 *Длительность воспроизведения в секундах 
		 * 
		 */
		/* 
		public function get duration() : Number
		 {
			 return _tracks[ 0 ].duration; 
		 }
		 
		 public function set duration( value : Number ) : void
		 {
			 for each( var track : Track in _tracks )
			 {
				 track.duration = value;
			 } 
		 }
		*/
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			_bpm = value;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				channel.bpm = _bpm;
			}
			
			if ( _channels.length > 0 )
			{
				_position = _channels[ 0 ].position;
				
				if ( _loop )
				{
					_startPosition = _channels[ 0 ].startPosition;
					_endPosition   = _channels[ 0 ].endPosition;
				}	
			}	
		}	
		
		public function getMeanGenre() : String
		{
			if ( ( numChannels == 0 ) || ( numSamples == 0 ) )
			{
				return 'na';
			}	
			
			var genre  : String = null;
			var genres : Object = new Object();
			
			for each( var ch : com.audioengine.sequencer.Sequencer in _channels )
			{
				for each( var note : Note in ch.listNote.notes )
				{
					genre = palette.getSample( note.source.id ).description.genre;
					
					if ( ! genres[ genre ] )
					{
						genres[ genre ] = 0.0;
					}
					
					genres[ genre ] += note.length
				}
			}
			
			var result   : String = null;
			var maxGenre : Number = 0.0;
			
			for( genre in genres )
			{
				if ( genres[ genre ] > maxGenre )
				{
					result = genre;
					maxGenre = genres[ genre ];
				}
			}	
			
			return result;
		}
		
		public function calculateCategory( channelNumber : uint ) : void
		{
			var channel    : com.audioengine.sequencer.Sequencer = _channels[ channelNumber ];
			var category   : String;
			var note       : Note;
			var categories : Object = new Object();
			
			var i : int = 0;
			
			for each( note in channel.listNote.notes )
			{
				category = palette.getSample( note.source.id ).description.category;
				
				if ( ! categories[ category ] )
				{
					categories[ category ] = 0.0;
				}
				
				categories[ category ] += note.length
			}
			
			var result      : String = null;
			var maxCategory : Number = 0.0;
			
			for( category in categories )
			{
				if ( categories[ category ] > maxCategory )
				{
					result = category;
					maxCategory = categories[ category ];
				}
			}
			
			if ( result != channel.data )
			{
				channel.data = result;
				dispatchEvent( new CategoryEvent( CategoryEvent.CHANGE, result, channelNumber ) );
			}
		}
		
		/*
		private function calculateBPMMeanValue() : void
		{
			var sum   : Number = 0;
			var count : int = 0;
			
			for each( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				for each( var note : Note in channel.listNote.notes )
				{
					var source : AudioLoop = note.source as AudioLoop;
					
					if ( ( source != null ) && source.loop )
					{
						sum += source.sample.bpm;
						count ++;
					}
				}
			}
			
			var newBPM : Number = _bpm;
			var oldBPM : Number = _bpm;
			
			if ( count > 0 )
			{
				newBPM = sum / count;
			}
			
			if ( newBPM != oldBPM )
			{
			  //bpm = newBPM;
			  dispatchEvent( new ChangeBPMEvent( ChangeBPMEvent.BPM_CHANGED, newBPM, oldBPM ) );
			}
		}
		*/
		/**
		 * Изменяет BPM секвенсора, отсылая при этом событие BPM_CHANGED 
		 * @param newBPM
		 * 
		 */		
		public function changeBPMTo( newBPM : Number ) : void
		{
			var oldBPM : Number = _bpm;
			
			if ( oldBPM != newBPM )
			{
				bpm = newBPM;
				dispatchEvent( new ChangeBPMEvent( ChangeBPMEvent.BPM_CHANGED, newBPM, oldBPM ) );
			}	
		}
		
		/**
		 * Общее количество всех семплов на секвенсоре 
		 * @return 
		 * 
		 */		
		public function get numSamples() : int
		{
			return _numSamples;
		}
		
		/**
		 * Общее количество реальных семплов, которые содержат реальные аудиоданные и не заблокированы 
		 * @return 
		 * 
		 */		
		public function get actualSamples() : int
		{
			return _actualSamples;
		}
				
		private var _numSamples : int = 0;
		
		private var _actualSamples : int = 0;
		
		/**
		 * Блокирует звучание определенной ноты на время, не удаляя из списка воспроизведения ( !!! Временная затычка, необходимо придумать что-то другое )
		 * @param note
		 * @param value
		 * 
		 */		
		public function lockNote( note : Note, value : Boolean ) : void
		{
			if ( note.source.locked != value )
			{
				if ( value ) _actualSamples --;
				else _actualSamples ++;
				
				note.source.locked = value;	
			}
		}
			
		/**
		 *Добавляет элемент исполнения на определенный трек 
		 * 
		 */
		 public function addNoteTo( note : Note, channelNumber : uint, calculateCategory : Boolean = true ) : void
		 {
			 _channels[ channelNumber ].listNote.add( note );
			 
			 if ( calculateCategory && ! _ignoreChanges )
			 {
				 this.calculateCategory( channelNumber );
			 }
			 
			if (  AudioLoop( note.source ).sample is AudioData )
			{
				_actualSamples ++;	
			}
			
			
			_numSamples ++;
			
			 
			 if ( ! _ignoreChanges )
			 dispatchEvent( new SequencerEvent( SequencerEvent.ADD_SAMPLE ) );
		 }
		 
		/**
		 * Удаляет элемент исполнения из определенного трека 
		 * 
		 */
		 public function removeNoteFrom( note : Note, channelNumber : uint, calculateCategory : Boolean = true ) : void
		 {
			 _channels[ channelNumber ].listNote.remove( note );
			 
			 if ( calculateCategory && ! _ignoreChanges )
			 {
				 this.calculateCategory( channelNumber );
			 }
			 
			 if ( AudioLoop( note.source ).sample is AudioData )
			 {
				_actualSamples --; 	
			 }
			 
			 _numSamples --;  
			 
			 if ( ! _ignoreChanges )
			 dispatchEvent( new SequencerEvent( SequencerEvent.REMOVE_SAMPLE ) );
		 }
		 
		 /**
		  * Проверяет есть ли указанная нота, на указанном канале 
		  * @param note
		  * @param channelNumber
		  * @return 
		  * 
		  */		 
		 public function noteExistsOnChannel( note : Note, channelNumber : uint ) : Boolean
		 {
			return _channels[ channelNumber ].listNote.exists( note );
		 }
		 
		 /**
		  * Проверяет существует ли дорожка с указанным номером 
		  * @param channelNumber
		  * @return 
		  * 
		  */		 
		 public function channelExists( channelNumber : uint ) : Boolean
		 {
			 return channelNumber < _channels.length;
		 }
		 
		 /**
		  * Возвращает ссылку на палитру семплов проекта 
		  * @return палитра семплов
		  * 
		  */		 
		 public function get palette() : SamplesPalette
		 {
			 return _palette;
		 }	 
		 
		 /**
		 * Запускает воспроизведение 
		 */
		public function play() : void
		{
			if ( ! _playing )
			{
				_driver.run();
				_playing = true;
				dispatchEvent( new SequencerEvent( SequencerEvent.START_PLAYING, _position ) );
			}	
		}
		
		/**
		 * Список указателей устройств с которых в данный момент происходит запись 
		 */		
		private var lines : Vector.<AudioInput>;
		
		/**
		 * Параметры записи  
		 */		
		private var waitParams : Vector.<Object>;
		
		/**
		 * На время записи отключаем режим петли и запоминаем состояние здесь 
		 */		
		private var _playLoop : Boolean;
		
		/**
		 * Инициирует процесс записи данных из устройства с указанным индексом в указанный буфер 
		 * @param to
		 * 
		 */		
		public function record( to : IAudioData, device_id : int = -1, routeToChannel : int = -1, loopBack : Boolean = false ) : void
		{	
			//Запись с микрофона не поддерживается 
			if ( ! AudioInput.isSuported )
			{	
				return;
			}
			
			var line : AudioInput = new AudioInput( device_id );
			
			var params : Object = {
				
				line : line,
				to   : to,
				routeToChannel : routeToChannel,
				loopBack       : loopBack
				
			};
			
			if ( ! waitParams )
			{
				waitParams = new Vector.<Object>();
			}	
			
			waitParams.push( params );
			
			if ( line.muted )
			 {
				line.addEventListener( StatusEvent.STATUS, onMicStatusChanged );
			 }
			 else
			 {	
			  initRecord( line, to, routeToChannel, loopBack );	
			 }
		}
		
		private function initRecord( line : AudioInput, to : IAudioData, routeToChannel : int, loopBack : Boolean ) : void
		{	
			line.loopBack = loopBack;	
			
			if ( routeToChannel != -1 )
			{	
				createSubChannelAt( routeToChannel );
				addToSubChannel( routeToChannel, line );
			}
			
			if ( ! lines )
			{
				lines = new Vector.<AudioInput>();
			}	
			
			lines.push( line );
			line.start( to );
			
			_playLoop = _loop;
			loop = false;
			
			if ( ! _playing )
			{	
				play();
			}
			
			_recording = true;
			dispatchEvent( new SequencerEvent( SequencerEvent.START_RECORDING, _position ) );
		}
		
		private function onMicStatusChanged( e : StatusEvent ) : void
		{
			var line   : AudioInput = AudioInput( e.target );
			var i      : int = 0;
			var params : Object;
			
			line.removeEventListener( StatusEvent.STATUS, onMicStatusChanged );
			
			while( i < waitParams.length )
			{
				params = waitParams[ i ];
				
				if ( params.line == line )
				{	
					break;
				}
				
				i ++;
			}	
			
			if ( e.code == AudioInput.UNMUTED )
			{
				initRecord( line, params.to, params.routeToChannel, params.loopBack );
			}
			else
			if ( e.code == AudioInput.MUTED )
			{
				
			}	
		}
		
		/**
		 *Останавливает воспроизведение 
		 */
		public function stop() : void
		{	
			//Если идет запись, то останавливаем процесс записи
			if ( _recording )
			{
				var i : int = 0;
				
				while( i < lines.length )
				{
					var line : AudioInput = lines[ i ];
					    line.stop();
					    line.dispose();
							
					var params : Object = waitParams[ i ];
					
					if ( params.routeToChannel != -1 )
					{
						removeSubChannelAt( params.routeToChannel );
					}	
							
					i ++;
				}
				
				lines  = null;
				params = null;
				
				loop = _playLoop;
				_recording = false;
			}	
			
			if ( _playing )
			{
				_driver.stop();
				_playing = false;
				
				dispatchEvent( new SequencerEvent( SequencerEvent.STOPPED, _position ) );
			}	
		}
		
		/**
		 * Возвращает область воспроизведения микса 
		 * @return 
		 * 
		 */		
		public function getPlayingArea( looped : Boolean ) : Object
		{
			return looped ? getLoopArea() : getRealArea();	
		}
		
		public function getLoopArea() : Object
		{
			var res : Object = new Object();
			    res.from     = int( _startPosition );
				res.to       = int( _endPosition );
			    res.length   = res.to - res.from;
			
			return res;
		}
		
		public function getRealArea() : Object
		{
			var res : Object = new Object();
			    res.from     = int( _realStart );
				res.to       = int( _realEnd );
			    res.length   = res.to - res.from;
			
			return res;
		}
		
		/**
		 * Положение курсора до сведения
		 */		
		private var lastPosition : Number;
		
		/**
		 * Режим зацикливания до сведения 
		 */		
		private var lastLoopMode : Boolean;
		
		/**
		 * Инициирует процесс записи музыки в поток данных
		 * Возвращает размер данных в байтах который должен в итоге получиться 
		 * 
		 */		
		public function beginMixDown( from : Number, to : Number ) : Number
		{	
			if ( _mixdown )
			 throw new Error( 'Mixdown already in progress.' );	
			
			stop();
			
			lastPosition = _position;
			position     = from;
			
			lastLoopMode = _loop;
			loop = false;
			
			_mixdown = true;
			
			return AudioData.framesToBytes( to - from );
		}
		
		/**
		 * Записывает в буфер поток данных указанной длины 
		 * @param data  - буфер для данных
		 * @param bytes - размер буфера в байтах
		 * 
		 */		
		public function mixdown( data : ByteArray, bytes : uint ) : void
		{
			_mixer.render( data, bytes );
			updatePosition();
		}
		
		/**
		 * Завершает процесс записи музыки в поток данных 
		 * 
		 */		
		public function endMixdown() : void
		{
			position = lastPosition;
			loop     = lastLoopMode;
			
			updatePosition();
			_mixdown = false;
		}	
		
		/**
		 * Идет процесс экспорта музыки в поток данных 
		 * 
		 */		
		public function get mixdowning() : Boolean
		{
			return _mixdown;
		}	
		
		/**
		 * Идет сейчас воспроизведение или нет 
		 */
		public function get playing() : Boolean
		{
			return _playing;
		}
		
		/**
		 * Идет сейчас процесс записи или нет 
		 * @return 
		 * 
		 */		
		public function get recording() : Boolean
		{
			return _recording;
		}
		
		public function clear() : void
		{
			removeAllChannels();	
			_palette.clear();
			
			_numSamples = 0;
			_actualSamples = 0;
			_position = 0.0;
			_startPosition = 0.0;
			_endPosition = 0.0;
			_realEnd = 0.0;
			_realStart = 0.0;
			_inverse = false;
			
			dispatchEvent( new SequencerEvent( SequencerEvent.POSITION_CHANGED, _position ) );
		}
		
		/**
		 * Удаляет неиспользовааные в проекте семплы из палитры
		 * 
		 */		
		public function compactPalette() : void
		{
			var pIds : Vector.<String> = new Vector.<String>();
			var id : String;
			
			//Ищем идентификаторы семплов использованные в миксе 
			for each ( var channel : com.audioengine.sequencer.Sequencer in _channels )
			{
				for each( var note : Note in channel.listNote.notes )
				{
					id = note.source.id;
					
					if ( pIds.indexOf( id ) == -1 )
						pIds.push( id );
				}
			}
			
			//Удаляем из палитры семплы не использованные в проекте
			var i : int = _palette.samples.length - 1;
			
			var desc    : BaseDescription;
			//Список сэмплов которые необходимо удалить
			var removed : Vector.<BaseDescription> = new Vector.<BaseDescription>(); 
			
			while( i >= 0 )
			{
				desc = _palette.samples.source[ i ].description;
				
				if ( pIds.indexOf( desc.id ) == -1 )
				{
					removed.push( desc );
				}
					
				i --;
			}
			
			if ( removed.length > 0 )
			{
				_palette.removeSamplesByDesc( removed );
				
				History.add( new HistoryRecord( new HistoryOperation( _palette, _palette.simpleAddSamples, removed ),
					                            new HistoryOperation( _palette, _palette.removeSamplesByDesc, removed ),
												'Отменить удаление неиспользуемых сэмплов',
												'Удалить неиспользуемые сэмплы' )
							);					
				
				dispatchEvent( new SequencerEvent( SequencerEvent.PALETTE_COMPACTED ) );
			}
		}
	}
}