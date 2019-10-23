package test
{
	import com.audioengine.calculations.PitchShift;
	import com.audioengine.utils.SoundUtils;
	
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	/**
	 * @author Andre Michelle (andre.michelle@gmail.com)
	 */
	public class MP3PitchLinearInterpolate 
	{
		private const BLOCK_SIZE: int = 3072;
		
		private var _mp3: Sound;
		private var _sound: Sound;
		private var _ch : SoundChannel;
		
		private var _target: ByteArray;
		
		private var _position: Number = 2257.0;
		private var _rate: Number = 0.9142857142857143;
		
		private var _pitcher : PitchShift;
		
		public function MP3PitchLinearInterpolate( url: String )
		{
			_target = new ByteArray();
			
			_mp3 = new Sound();
			_mp3.addEventListener( Event.COMPLETE, complete );
			_mp3.load( new URLRequest( url ) );
			
			
			_rate = 1.0;
			
			_sound = new Sound();
			_sound.addEventListener( SampleDataEvent.SAMPLE_DATA, sampleData );
			
			_pitcher = new PitchShift();
		}
		
		public function get rate(): Number
		{
			return _rate;
		}
		
		public function set rate( value: Number ): void
		{
			if( value < 0.0 )
				value = 0;
			
			_rate = value;
		}
		
		private function complete( event: Event ): void
		{
			//_sound.play();
		}
		
		public function start() : void
		{
			_ch = _sound.play();
		}
		
		public function stop() : void
		{
			_ch.stop();
			_ch = null;
		}
		
		private function sampleData( event: SampleDataEvent ): void
		{
			_rate = 1.09375;
			
			//-- REUSE INSTEAD OF RECREATION
			_target.position = 0;
			
			//-- SHORTCUT
			var data: ByteArray = event.data;
			
			/*var scaledBlockSize: Number = BLOCK_SIZE * _rate;
			var input : ByteArray = new ByteArray();
			
			var positionInt: int = _position;
			var alpha: Number = _position - positionInt;
			
			var need: int = Math.ceil( scaledBlockSize ) + 2;
			
			var read: int = _mp3.extract( input, need, positionInt );
			
			_pitcher.length = read < BLOCK_SIZE ? BLOCK_SIZE : read;
			_pitcher.rate = _rate;
			_pitcher.alpha = alpha;
			_pitcher.input = input;
			_pitcher.size = read == need ? BLOCK_SIZE : read / _rate;
			
			input.length = _pitcher.length << 3;
			_pitcher.calculate( event.data );
			
			//SoundUtils.traceByteArray( input );
			//SoundUtils.traceByteArray( event.data );
			
			event.data.length = BLOCK_SIZE << 3;
			
			//SoundUtils.traceByteArray( event.data );
			
			if ( read != need ) _position = 0.0;
			 else _position += scaledBlockSize;*/
			
			var scaledBlockSize: Number = BLOCK_SIZE * _rate;
			var positionInt: int = _position;
			var alpha: Number = _position - positionInt;
			
			var positionTargetNum: Number = alpha;
			var positionTargetInt: int = -1;
			
			//-- COMPUTE NUMBER OF SAMPLES NEED TO PROCESS BLOCK (+2 FOR INTERPOLATION)
			var need: int = Math.ceil( scaledBlockSize ) + 2;
			
			//-- EXTRACT SAMPLES
			var read: int = _mp3.extract( _target, need, positionInt );
			
			var n: int = read == need ? BLOCK_SIZE : read / _rate;
			
			var l0: Number;
			var r0: Number;
			var l1: Number;
			var r1: Number;
			var newAlpha : Number = alpha;
			
			//SoundUtils.traceByteArray( _target );
			
			for( var i: int = 0 ; i < n ; ++i )
			{
				//-- INCREASE TARGET POSITION
				positionTargetNum = _rate * i + alpha;
				
				//-- INCREASE FRACTION AND CLAMP BETWEEN 0 AND 1
				newAlpha = positionTargetNum;
				
				//while( alpha >= 1.0 ) --alpha;
				newAlpha -= Math.floor( newAlpha );
				
				//-- AVOID READING EQUAL SAMPLES, IF RATE < 1.0
				if( int( positionTargetNum ) != positionTargetInt )
				{
					positionTargetInt = positionTargetNum;
					
					//-- SET TARGET READ POSITION
					_target.position = positionTargetInt << 3;
					
					//-- READ TWO STEREO SAMPLES FOR LINEAR INTERPOLATION
					l0 = _target.readFloat();
					r0 = _target.readFloat();
					
					l1 = _target.readFloat();
					r1 = _target.readFloat();
				}
				
				//trace( i +  ' -- > ' + l0 + ',' + l1 );
				
				//-- WRITE INTERPOLATED AMPLITUDES INTO STREAM
				data.writeFloat( l0 + newAlpha * ( l1 - l0 ) );
				data.writeFloat( r0 + newAlpha * ( r1 - r0 ) );
				
				
			}
			trace( 'read :' + read );
			SoundUtils.traceByteArray( data );
			
			//-- FILL REST OF STREAM WITH ZEROs
			if( i < BLOCK_SIZE )
			{
				while( i < BLOCK_SIZE )
				{
					data.writeFloat( 0.0 );
					data.writeFloat( 0.0 );
					
					++i;
				}
				_position = 2257.0;
			}
			else
			//-- INCREASE SOUND POSITION
			_position += scaledBlockSize;
		}
	}
}
