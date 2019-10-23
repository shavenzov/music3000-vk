
import mx.collections.ArrayCollection;


import spark.events.IndexChangeEvent;

import classes.api.MainAPI;

import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;

private static const items : Array = [
	{ icon : Assets.SAMPLE_ICON, feature : 'Сэмплы', basic : 'В формате <b>MP3</b> (128 кбит/с)', pro : 'Оригинального качества в форматах: <b>WAVE</b> и <b>AIFF</b>*' },
    { icon : Assets.MIXDOWN, feature : 'Публикация', basic : 'В "Мои Аудиозаписи". <br> Качество <b>MP3</b> (128 кбит/с)', pro : 'В форматах:<br><b>MP3</b> (128/196/320 кбит/с),<br><b>WAVE</b> (CD/PRO/MAXIMUM)' },
	{ icon : Assets.MIX, feature : 'Миксы', basic : 'Максимальное количество : <b>16</b>**', pro : 'Неограниченное количество**' },
	{ icon : Assets.FAVORITE_BIG_ICON, feature : 'Избранное', basic : 'Нет', pro : 'Возможность добавлять понравившиеся сэмплы в избранное' },
	{ icon : Assets.UNDO_ICON, feature : 'Отмена действий', basic : 'Нет', pro : 'Неограниченное количество' },
	{ icon : Assets.CLOCK_ICON_WHITE, feature : 'Длина микса', basic : '5 минут', pro : '60 минут' },
	{ icon : Assets.STOP_ICON, feature : 'Реклама', basic : 'Есть', pro : 'Нет' }
	                                 ];

private function onTableChanging( e : IndexChangeEvent ) : void
{
	e.preventDefault();
}

private function onCloseClick() : void
{
	ApplicationModel.userInfo.visible = true;
	
	dispatchEvent( new BackEvent( BackEvent.BACK ) );
}

private function onProClick() : void
{
	ApplicationModel.userInfo.visible = true;
	
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.ADD_PRO_MODE, null, initializedAction.fromIndex, initializedAction.fromState ) );
}

private function onShow() : void
{
	currentState = initializedAction.fromIndex == -1 ? 'fromOther' : 'fromMenu';
	addButton.label = MainAPI.impl.userInfo.pro ? 'Продлить' : 'Подключить';
	
	ApplicationModel.userInfo.visible = false;
}