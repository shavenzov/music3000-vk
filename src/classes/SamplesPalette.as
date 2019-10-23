/**
 * Реализует функционал звуковой палитры используемой в секвенсоре 
 */
package classes
{
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.events.PaletteErrorEvent;
	import classes.soundwave.SoundWaveGraphicCache;
	
	import com.audioengine.sources.IAudioDataSource;
	import com.audioengine.sources.SourceManager;
	import com.serialization.IXMLSerializable;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	
	import mx.collections.ArrayCollection;


	public class SamplesPalette extends EventDispatcher implements IXMLSerializable
	{
		/**
		 * Максимальное количество одновременно загружаемых семплов 
		 */		
		public static const MAX_PARALLEL_REQUESTS : uint = 4;
		
		/**
		 * Список семплов в палитре 
		 */
		public var samples : ArrayCollection = new ArrayCollection();
		
		
		/**
		 * Список семплов ожидающих загрузки 
		 */		
		private var inqueue : Vector.<IAudioDataSource> = new Vector.<IAudioDataSource>();
		
		/**
		 * Список загружаемых в данный момент семплов 
		 */		
		private var loaders : Vector.<IAudioDataSource> = new Vector.<IAudioDataSource>();
		
		/**
		 * Общее количество данных необходимых для загрузки 
		 */		
		private var _total : int;
		/**
		 * Количество загруженных данных 
		 */		
		private var _progress : int;
		
		/**
		 * Дополнительная прибавка при подсчете общего хода загрузки семплов 
		 */		
		private var _balance : int; 
		
		/**
		 * Количество семплов загружаемых в данный момент 
		 */		
		private var _loading_samples : int;
		
		/**
		 * Список изображений звуковых волн 
		 */		
		public var waves : SoundWaveGraphicCache = new SoundWaveGraphicCache();
		
		/**
		 * Игнорировать изменения ( Не отсылать сообщения о добавлении ) 
		 */		
		private var _ignoreChanges : Boolean;
			
		private var api : MainAPIImplementation;
		
		public function SamplesPalette()
		{
		  super();
		  api = MainAPI.impl;
		}
		
		public function get ignoreChanges() : Boolean
		{
			return _ignoreChanges;
		}
		
		public function set ignoreChanges( value : Boolean ) : void
		{
			_ignoreChanges = value;
			
			if ( _ignoreChanges )
			{
				samples.disableAutoUpdate();
			}
			else
			{
				samples.enableAutoUpdate();
			}
		}
		
		/**
		 *Добавляет семпл из библиотеки в палитру инициируя загрузку семпла, если это необходимо
		 *( Информацию о ходе загрузки семпла, можно получить используя св-во loader PaletteSample )
		 * 
		 * Возвращает образец PaletteSample
		 * Если такого семпла нет в палитре, то добавляет его инициирую загрузку
		 */
		public function add( sd : BaseDescription  ) : PaletteSample
		{
			var sample : PaletteSample = getSample( sd.id );
			
			if ( ( ! sample ) || ( ! sample.source && ! sample.loader ) )
			{
				    var loader : IAudioDataSource = SourceManager.getAudioDataSourceByFileExt( api.userInfo.pro ? sd.hqurl : sd.lqurl, sd.id, sd.bpm, sd.loop );
					   
				    if ( ! sample )
					{
						sample = new PaletteSample( sd );
					}
					
					sample.setLoader( loader );
					setSample( sample );
					
					putToQueue( loader );
			}
			
			return sample;
		}
		
		private function putToQueue( loader : IAudioDataSource ) : void
		{
			if ( loaders.length < MAX_PARALLEL_REQUESTS )
			{
				setLoaderListeners( loader );
				loaders.push( loader );
				loader.load();
			}
			else
			{
				inqueue.push( loader );
			}
		}
		
		private function getSampleByLoader( loader : IAudioDataSource ) : PaletteSample
		{
			for each( var ps : PaletteSample in samples.source )
			 if ( ps.loader == loader )
			 {
				 return ps;
			 }
			
			return null;
		}
		
		private function setLoaderListeners( loader : IAudioDataSource ) : void
		{
			loader.addEventListener( Event.COMPLETE, onSampleLoaded, false, 1000 );
			loader.addEventListener( ProgressEvent.PROGRESS, onProgress, false, 1000 );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onSampleError, false, 1000 );
			loader.addEventListener( ErrorEvent.ERROR, onSampleError, false, 1000 );
		}
		
		private function removeLoaderListeners( loader : IAudioDataSource ) : void
		{
			loader.removeEventListener( Event.COMPLETE, onSampleLoaded );
			loader.removeEventListener( ProgressEvent.PROGRESS, onProgress );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onSampleError );
			loader.removeEventListener( ErrorEvent.ERROR, onSampleError );
		}
		
		/**
		 * Удаляет указанный loader из указанного списка list 
		 * @param list
		 * @param loader
		 * return true если loader найден в списке и удален
		 */		
		private function removeLoaderFrom( list : Vector.<IAudioDataSource>, loader : IAudioDataSource ) : Boolean
		{
		  var itemIndex : int = list.indexOf( loader );
		  
		  if ( itemIndex != -1 )
		  {
			  list.splice( itemIndex, 1 );
			  return true;
		  }
		  
		  return false;
		}
		
		private function recalcProgress() : void
		{
			var loader : IAudioDataSource; 
			
			_total    = _balance;
			_progress = _balance;
			
			for each( loader in loaders )
			{
				_total    += loader.total;
				_progress += loader.progress;
			}
			
			for each( loader in inqueue )
			{
				_total    += loader.total;
				_progress += loader.progress; 
			}
			
			//trace( _progress, _total );
			//trace( 'monitor', inqueue.length, loaders.length );
		}	
		
		private function onProgress( e : ProgressEvent ) : void
		{
			recalcProgress();
			dispatchEvent( new ProgressEvent( ProgressEvent.PROGRESS, false, false, _progress, _total ) );
		}	
		
		private function onSampleError( e : ErrorEvent ) : void
		{
			var loader : IAudioDataSource = IAudioDataSource( e.currentTarget ); 
			var sample : PaletteSample = getSampleByLoader( loader );
			    
			if ( sample )
			{
				sample.error = true;
			}
			
			if ( hasEventListener( PaletteErrorEvent.ERROR ) )
			{   
				dispatchEvent( new PaletteErrorEvent( PaletteErrorEvent.ERROR, sample, e.text, e.errorID ) );	
			}
			
			_balance += loader.total;
			
			removeLoaderListeners( loader );
			removeLoaderFrom( loaders, loader );
			recalcProgress();
						
			next();
		}
		
		private function onSampleLoaded( e : Event ) : void
		{
			var loader : IAudioDataSource = IAudioDataSource( e.currentTarget );
			var sample : PaletteSample = getSampleByLoader( loader );
			
			if ( sample )
			{
				sample.error = false;
				//Устанавливаем св-во source для семпла в палитре
				sample.setSource( loader.source );
				sample.setLoader( null );
			}
			
			_balance += loader.total;	
				
			removeLoaderListeners( loader );
			removeLoaderFrom( loaders, loader );
			recalcProgress();
			
			next();	
		}
		
		private function next() : void
		{
			if ( inqueue.length > 0 )
			{
				putToQueue( inqueue.shift() );
			}
			else if ( loaders.length == 0 )
			{
				dispatchEvent( new Event( Event.COMPLETE ) );
				_balance = 0;
				_total = 0;
				_progress = 0;
			 } 
		}
		
		/**
		 * Добавляет семпл в палитру
		 * @param sample
		 * 
		 */		
		public function addSample( sample : PaletteSample ) : void
		{
			samples.addItem( sample );
		}
		
		/**
		 * Добавляет сэмпл в палитру, не инициализирую его загрузку по описанию
		 * @param sd
		 * 
		 */		
		public function simpleAdd( sd : BaseDescription ) : void
		{
			var sample : PaletteSample = getSample( sd.id );
			
			if ( ! sample )
			{
				addSample( new PaletteSample( sd ) );
			}
		}
		
		/**
		 * Добавляет несколько сэмплов в палитру, не инициализируя их загрузку по описанию 
		 * @param samples
		 * 
		 */		
		public function simpleAddSamples( sds : Vector.<BaseDescription> ) : void
		{
			ignoreChanges = true;
			
			for each( var sd : BaseDescription in sds )
			{
				simpleAdd( sd );
			}
			
			ignoreChanges = false;
		}
		
		/**
		 * Удаляет семпл из палитры по его идентификатору
		 *  
		 * @param sid
		 * 
		 */		
		public function removeSampleById( sid : String ) : void
		{
			for( var i : int = 0; i < samples.length; i ++ )
			{
				var sample : PaletteSample = PaletteSample( samples.source[ i ] );
				
				if ( sample.description.id == sid )
				{
					if ( sample.loader )
					{
						//Удаляем loader из очереди на загрузку
						if ( sample.loader.loading ) //Загружаемых в данный момент
						{
							removeLoaderListeners( sample.loader );
							sample.loader.close();
							removeLoaderFrom( loaders, sample.loader )
						}
						else //Ожидающих загрузку
						{
							removeLoaderFrom( inqueue, sample.loader )
						}
					}
					
					if ( sample.source )
					{
						sample.source.dispose();	
					}
					
					samples.removeItemAt( i );
					
					break;
				}	
			}	
		}
		
		public function removeSample( sample : PaletteSample ) : void
		{
			removeSampleById( sample.description.id );
		}
		
		public function removeSampleByDesc( sd : BaseDescription ) : void
		{
			removeSampleById( sd.id );
		}
		
		public function removeSamplesByDesc( sds : Vector.<BaseDescription> ) : void
		{
			ignoreChanges = true;
			
			for each( var sd : BaseDescription in sds )
			{
				removeSampleById( sd.id );
			}
			
			ignoreChanges = false;
		}
		
		/**
		 * 
		 * @param sid
		 * @return Возвращет true, если такой семпл с таким id уже имеется в палитре
		 * 
		 */		
		public function exists( sid : String ) : Boolean
		{
		    return getSample( sid ) != null;	
		}
		
		/**
		 *Возвращает семпл из палитры по его идентификатору или null, если такого не найдено
		 *  
		 * @param sid
		 * @return PaletteSample
		 * 
		 */		
		public function getSample( sid : String ) : PaletteSample
		{
			for each( var sample : PaletteSample in samples.source )
			{
				if ( sample.description.id == sid ) 
				{
					return sample;
				}	
			}
			
			return null;
		}
		
		/**
		 * Заменяет описание сэмпла с указанным идентификатором, если такого описания нет, то добавляет 
		 * @param sd
		 * retur true если сэмпл был добавлен, false - заменен
		 */		
		public function setSample( sd : PaletteSample ) : void
		{
			for( var i : int = 0; i < samples.source.length; i ++ )
			{
				if ( samples.source[ i ].description.id == sd.description.id ) 
				{
					samples.setItemAt( sd, i );
					return;
				}
			}
			
			addSample( sd );
		}
		
		/**
		 * Скидывает все семплы пользователя на сервер
		 * 
		 */		
		public function flush() : void
		{	
			
		}
		
		/**
		 * Очищает палитру ( делает её пустой ) 
		 * 
		 */		
		public function clear() : void
		{
			for each( var sample : PaletteSample in samples.source )
			{
			   if ( ( sample.loader ) && ( sample.loader.loading ) )
				{
					sample.loader.close();
					removeLoaderListeners( sample.loader );
				}
				
				if ( sample.source )
				{
					sample.source.dispose();	
				}
			}
			
			loaders.length = 0;
			inqueue.length = 0;
			samples.removeAll();
			
			waves.clear();
			
			_total = 0;
			_progress = 0;
			_balance = 0;
		}	
		
		/**
		 * Определяет подгружаются ли в данный момент семплы в палитру 
		 * @return 
		 * 
		 */		
		public function get loading() : Boolean
		{
			return loaders.length != 0;
		}	
		
		public function serializeToXML() : String
		{
            /*
			<palette>
			 <sample id="1" />
			</palette>
			*/
			
			var str : String = '';
			
			str += '<palette>';
			
			for each( var sp : PaletteSample in samples.source )
			{
			  str += sp.description.serializeToXML();	 
			}
			
			str += '</palette>';
			
			return str;
		}
		
		
	}
}