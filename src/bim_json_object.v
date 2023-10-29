import os
import json

/// Набор возможных типов элеметов здания:
/// ROOM, STAIR, DOOR_WAY, DOOR_WAY_INT, DOOR_WAY_OUT, OUTSIDE
enum BimElementSign {
	room ///< Указывает, что элемент здания является помещением/комнатой
	staircase ///< Указывает, что элемент здания является лестницей
	door_way ///< Указывает, что элемент здания является проемом (без дверного полотна)
	door_way_int ///< Указывает, что элемент здания является дверью, которая соединяет
	///< два элемента: ROOM и ROOM или ROOM и STAIR
	door_way_out ///< Указывает, что элемент здания является эвакуационным выходом
	outside ///< Указывает, что элемент является зоной вне здания
	undefined ///< Указывает, что тип элемента не определен
}

/// Структура, описывающая элемент
struct BimJsonElement {
	uuid    string    [json: Id]        ///< [JSON] UUID идентификатор элемента
	name    string    [json: Name]      ///< [JSON] Название элемента
	xy      []Polygon [json: XY]     ///< [JSON] Полигон элемента
	outputs []string  [json: Output]  ///< [JSON] Массив UUID элементов, которые являются соседними
	id      usize     [skip] ///< Внутренний номер элемента (генерируется)
	size_z  f64       [json: SizeZ] ///< [JSON] Высота элемента
	// z_level f64 [skip]       ///< Уровень, на котором находится элемент
	sign string [json: Sign] ///< [JSON] Тип элемента
}

/// Структура поля, описывающего географическое положение объекта
struct BimJsonAddress {
	city           string [json: City] ///< [JSON] Название города
	street_address string [json: StreetAddress] ///< [JSON] Название улицы
	add_info       string [json: AddInfo]       ///< [JSON] Дополнительная информация о местоположении объекта
}

/// Структура, описывающая этаж
struct BimJsonLevel {
	name     string           [json: NameLevel] ///< [JSON] Название этажа
	elements []BimJsonElement [json: BuildElement] ///< [JSON] Массив элементов, которые принадлежат этажу
	z_level  f64              [json: ZLevel] ///< [JSON] Высота этажа над нулевой отметкой
	// numofelements usize  ///< Количство элементов на этаже
}

/// Структура, описывающая здание
struct BimJsonObject {
	address BimJsonAddress [json: Address] ///< [JSON] Информация о местоположении объекта
	name    string         [json: NameBuilding] ///< [JSON] Название здания
	levels  []BimJsonLevel [json: Level] ///< [JSON] Массив уровней здания
}

fn bim_json_new(file_name string) BimJsonObject {
	bim_json_string := os.read_file(file_name) or {
		panic('Failed to open bim json. Error: ${err}')
	}

	return json.decode(BimJsonObject, bim_json_string) or {
		panic('Failed to decode BimJsonObject. Error: ${err}')
	}
}
