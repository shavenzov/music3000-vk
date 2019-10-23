/**
 * Реализует одну из дорожек секвенсора
 * 
 * Ключевые параметры (Все указанные ниже параметры в фреймах)
 * position     - текущее положение курсора воспроизведения
 * realDuration - Позиция окончания воспроизведения последнего семпла в списке
 * duration     - Длина дорожки
 * 
 * loop : Boolean - Вкл\выкл воспроизведение с startPosition до endPosition
 * 		Следующие параметры имеют место, только при loop = true
 * 			startPosition - Позиция начала петли
 * 			endPosition   - Позиция окончания петли  
 */
package com.audioengine.sequencer
{
	import com.audioengine.calculations.Invert;
	import com.audioengine.calculations.Mix;
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IProcessor;
	import com.audioengine.sequencer.events.SequencerEvent;
	import com.audioengine.utils.SoundUtils;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

	public class Sequencer extends EventDispatcher implements IProcessor
	{
		/**
		 * Произвольные данные привязанные к секвенсору 
		 */		
		public var data : *;
		/**
		 * Скорость воспроизведения ударов в минуту 
		 */		
		private var _bpm : Number = 140.0;
		
		/**
		 * Положение курсора воспроизведения в фреймах 
		 */		
		private var _position : Number = 0.0;
		
		/**
		 * Позиция после рендеринга 
		 */		
		private var _lastPosition : Number;
		
		/**
		 * Положение маркера стартовой позиции петли 
		 */		
		private var _startPosition : Number;
		
		/**
		 * Положение маркера конечной позиции петли
		 * Если равно NaN, то будет высчитываться конец самого последнего семпла в списке воспроизведения 
		 */		
		private var _endPosition   : Number;
		
		/**
		 * Длительность дорожки в фреймах 
		 */		
		private var _duration : Number;
		
		/**
		 * Указывает будет ли ввоспроизведение зацикленным 
		 */		
		public var loop : Boolean;
		
		/**
		 * Если true, то после рендеринга положения курсора воспроизведения не меняется
		 * Позиция меняется только из вне 
		 */		
		public var captured : Boolean;
		
		/**
		 * Ноты секвенсора 
		 */		
		private var _listNote : ListNote;
		
		/**
		 * Класс производящий сложение семплов в секвенсоре за указанный промежуток времени 
		 */		
		private var _mixer    : Mix;
		
		/**
		 * Инвертор потока данных для воспроизведения справа на лево 
		 */		
		private var _invertor : Invert;
		
		/**
		 * Нулевые данные 
		 */		
		private const zeroBytes: ByteArray = new ByteArray();
		
		/**
		 * Воспроизводить ли данные справа на лево
		 */		
		public var inverse : Boolean;
		
		public function Sequencer()
		{
		  _mixer    = new Mix();
		  _invertor = new Invert();
		}	
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			if ( _listNote )
			{
				_listNote.bpm = value;
			}
			
			if ( loop )
			{
				var k : Number = _bpm / value;
				_startPosition *= k;
				_endPosition *= k;
				_position *= k;
			}
			
			_bpm = value;
		}	
		
		public function get listNote() : ListNote
		{
			return _listNote;
		}
		
		public function set listNote( value : ListNote ) : void
		{
		   _listNote = value;	
		}
		
		public function get position() : Number
		{
			return _position;
		}
		
		public function set position( value : Number ) : void
		{
			_position = value;
		}
		
		public function get startPosition() : Number
		{
			return isNaN( _startPosition ) ? 0 : _startPosition;
		}
		
		public function set startPosition( value : Number ) : void
		{
			_startPosition = value;
		}
		
		public function set endPosition( value : Number ) : void
		{
			_endPosition = value; 
		}	
		
		public function get endPosition() : Number
		{
			return isNaN( _endPosition ) ? _duration : _endPosition;
		}
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
			_duration = value;
		}	
		
		/**
		 * Окончание воспроизведения самой последней ноты в списке воспроизведения 
		 * @return 
		 * 
		 */		
		public function get realEnd() : Number
		{
			return _listNote ? _listNote.end : 0;
		}
		
		/**
		 * Начало воспроизведения самой первой ноты в списке 
		 * @return 
		 * 
		 */		
		public function get realStart() : Number
		{
			return _listNote ? _listNote.start : 0;
		}
		
		/**
		 * Определяет пустая ли дорожка севенсора или нет 
		 * @return 
		 * 
		 */		
		public function get isEmpty() : Boolean
		{
			return ( _listNote == null ) || ( _listNote.notes.length == 0 );
		}	
		
		private function invertData( data : ByteArray, bytes : uint ) : void
		{
			_invertor.bytesLength = bytes;
			_invertor.input = data;
			_invertor.calculate( data );
		}
		
		private function getSamples( pos : Number, length : Number, bytes : uint, offset : Number, invert : Boolean = false ) : Vector.<ByteArray>
		{
				var notes      : Vector.<Note> = _listNote.getRange( pos, pos + length );
				var note       : Note;
				var i          : int = 0;
				var dstOffset  : Number;
				var srcOffset  : Number;
				var len        : Number;
				var samples    : Vector.<ByteArray>;
				var sample     : ByteArray;
			
				if ( notes.length > 0 )
				{
					samples = new Vector.<ByteArray>( notes.length );
					
					while( i < notes.length )
					{
						note = notes[ i ];
						//trace( 'zz', pos, note.start );
						srcOffset = Math.max( pos - note.start, 0 );
						dstOffset = Math.max( note.start - pos, 0 );
						len    = Math.min( note.source.length - srcOffset, length - dstOffset ); 
						
						sample = new ByteArray();
						sample.length = bytes;
						
						if ( invert )
						{
							var buffer : ByteArray = new ByteArray();
							    buffer.length = AudioData.framesToBytes( len );
								
							note.source.copy( buffer, srcOffset, 0, len, invert );
							invertData( buffer, buffer.length );
							
			                //Определяем мы находимся в начале или конце семпла
							dstOffset = Math.max( ( pos + length ) - note.end, 0 );
							sample.position = AudioData.framesToBytes( dstOffset + offset );
								
							
							sample.writeBytes( buffer );
						}	
						else
						{
							note.source.copy( sample, srcOffset, dstOffset + offset, len, invert );
						}
						
						samples[ i ] = sample;
						i ++;
					}
					
					return samples;
				}
			
			return new Vector.<ByteArray>();
		}	
		
		private function mixSamples( data : ByteArray, samples : Vector.<ByteArray> ) : void
		{
			//Смешиваем все извлеченные куски
			_mixer.bytesLength = samples[ 0 ].length;
			_mixer.samples = samples;
			_mixer.calculate( data );
		}	
		
		private function dispatchEvents() : void
		{
			if ( inverse )
			{
				if ( _position <= 0 )
				{
					dispatchEvent( new SequencerEvent( SequencerEvent.END, _position ) );
				}	
			}
			else
			{
				if ( _position >= _duration )
				{
					dispatchEvent( new SequencerEvent( SequencerEvent.END, _position ) );
				}
				else
					if ( _position >= realEnd )
					{
						dispatchEvent( new SequencerEvent( SequencerEvent.END_MUSIC, _position ) ); 
					}
			}
		}	
		
		public function render( data : ByteArray, bytes : uint ) : void
		{
			if ( captured && ( _position == _lastPosition ) )
			{
				//Заполняем нулями буфер	
				zeroBytes.length = bytes;
				data.writeBytes( zeroBytes );
				
				return;
			}	
			
			var numSamples : Number = AudioData.bytesToFrames( bytes );
			var samples    : Vector.<ByteArray> = new Vector.<ByteArray>();
			var jumpedToStart : Boolean; //Определяет произошел ли переход на начало петли
			var cPos     : Number = _position;
			var startPos : Number = loop ? ( cPos > startPosition ? startPosition : 0 ) : - numSamples;
			var endPos   : Number = loop ? ( cPos < endPosition ? endPosition : duration ) : duration + numSamples;
				
			var remains  : Number = numSamples;
			var cLength  : Number;
			var offset   : Number = 0.0;
					
			//Подготавливаем список семплов для смешивания
			while ( remains > 0.0 )
			 {
				if ( inverse ) //При воспроизведении обратно
				 {
					cLength = Math.min( cPos - startPos, remains );
									
					samples = samples.concat( getSamples( cPos - cLength, cLength, bytes, offset, true ) );
							
					if ( ( cPos - startPos ) > remains )
					{
						cPos -= remains;
					}
					else
					{
					    cPos = endPos;
						jumpedToStart = true;
					}
							
					offset += cLength;
					remains -= cLength;	
				}
				else //При воспроизведении туда
				 {
					//Определяем длину копируемого куска
					cLength = Math.min( endPos - cPos, remains ); 
					samples = samples.concat( getSamples( cPos, cLength, bytes, offset ) );
							
					if ( ( endPos - cPos ) > remains )
					 {
						cPos += remains;
					 }
					 else
					  {
						cPos = startPos;
						jumpedToStart = true;
					  }	
							
					offset += cLength;
					remains -= cLength;
				  }		
				}
					
			//Устанавливаем новое положение курсора воспроизведения
			_lastPosition = _position;
		    
			if ( ! captured )
			{
				_position = cPos;
			}	
					
			//Смешиваем извлеченные куски
			if ( samples.length > 0 )
			{
			  if ( samples.length == 1 )
			   {
					data.writeBytes( samples[ 0 ] );
				}
				else
				{
				  mixSamples( data, samples );
				}
			 }
			 else
			  {
				//Заполняем нулями буфер	
			    zeroBytes.length = bytes;
			    data.writeBytes( zeroBytes );
			  }
			
			//SoundUtils.traceByteArray( data );
			//SoundUtils.testAudioData( data );
			
			//Если произошел переход на начало петли, то отсылаем соответствующее событие
		    if ( ! captured )
			{
				if ( jumpedToStart )
				{
					dispatchEvent( new SequencerEvent( SequencerEvent.END_LOOP, _position ) );
				} //проверяем на закончилась ли дорожка, и если закончилась отправляем соответствующее событие
				else
				{
					dispatchEvents();	
				}
			}
		}	
	}
}