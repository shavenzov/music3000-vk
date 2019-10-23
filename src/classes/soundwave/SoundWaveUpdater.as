package classes.soundwave
{
	import com.thread.BaseRunnable;
	
	import flash.events.Event;

	public class SoundWaveUpdater extends BaseRunnable
	{
		private var _data : ISoundWaveGraphic;
		
		public function SoundWaveUpdater( data : ISoundWaveGraphic )
		{
			super( -1 );
			_name = 'SoundWaveUpdater';
			data.startUpdate();
			_total = data.iterations;
			
			_data = data;
		}
		
		override public function process():void
		{
			/*
			 Проверка, во время процесса рендеринга волна может быть внезапно очищена
			*/
			if ( _data.rendering )
			{
				_data.update();
				_progress = _data.currentIteration;
			}
			else
			{
				//В этом случае завершаем процесс обновления звуковой волны
				_progress = _total;
				return;
			}
			
			if ( _progress == _total )
			{
			  _data.endUpdate();
			  _data.locked = false;
			}	
		}	
	}
}