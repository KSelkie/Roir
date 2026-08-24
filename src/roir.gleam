import gleam/float
import gleam/time/duration
import gleam/int
import lustre/attribute as a
import lustre
import lustre/element.{type Element}
import lustre/element/html as h
import lustre/event
import lustre/effect
import gleam/time/calendar
import gleam/time/timestamp as t
import plinth/javascript/global
import gleam/result

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model { Model(
  page: Page,

  time: t.Timestamp,

  dist_conversion: DistConversion,
  weight_conversion: WeightConversion,
  time_conversion: TimeConversion,
  temp_conversion: TempConversion
)}

type Page {
  Home
  Clock
  Conversion
}

type DistConversion {DistConversion(
  dist: Float,
  num_per_meter1: Float,
  num_per_meter2: Float
)}

type WeightConversion {WeightConversion(
  weight: Float,
  num_per_kg1: Float,
  num_per_kg2: Float
)}

type TimeConversion {TimeConversion(
  time: Float,
  num_in_seconds1: Float,
  num_in_seconds2: Float
)}

type TempConversion {TempConversion(
  temp: Float,
  steps_per_c1: Float,
  temp_at_freezing1: Float,
  steps_per_c2: Float,
  temp_at_freezing2: Float
)}

fn init(_flags) -> #(Model, effect.Effect(Message)) {
  #(Model(
    Home,
    t.system_time(),
    DistConversion(0.0, 50.0 /. 1.27, 29.386561536 /. 3.747405725),
    WeightConversion(0.0, 10.0 /. 4.5359237, 3.172169114198268924301601144832 /. 6.578125590179196664876931640625),
    TimeConversion(0.0, 1.0, 2.5 /. 2.7),
    TempConversion(32.0, 1.8, 32.0, 2.16, 0.0)
  ), effect.none())
}

type Message {
  UserClickedHome
  UserClickedClock
  UserClickedConversion

  ClockTick

  UserDistance(dist: Float)
  DistanceRatio1(num_per_meter: Float)
  DistanceRatio2(num_per_meter: Float)

  UserWeight(weight: Float)
  WeightRatio1(num_per_kg: Float)
  WeightRatio2(num_per_kg: Float)

  UserTime(time: Float)
  TimeRatio1(num_per_second: Float)
  TimeRatio2(num_per_second: Float)

  UserTemp(temp: Float)
  TempRatio1(steps_per_c: Float, temp_at_freezing: Float)
  TempRatio2(steps_per_c: Float, temp_at_freezing: Float)

  None
}

fn update(model : Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    UserClickedHome -> #(Model(Home, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())
    UserClickedClock -> case model.page {
      Clock -> #(Model(Clock, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())
      _ -> #(Model(Clock, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, model.temp_conversion), effect.from(tick))
    }
    UserClickedConversion -> case model.page {
      Conversion -> #(Model(Conversion, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())
      _ -> #(Model(Conversion, t.system_time(), DistConversion(0.0, 50.0 /. 1.27, 29.386561536 /. 3.747405725), WeightConversion(0.0, 10.0 /. 4.5359237, 3.172169114198268924301601144832 /. 6.578125590179196664876931640625), TimeConversion(0.0, 1.0, 2.5 /. 2.7), TempConversion(32.0, 1.8, 32.0, 2.16, 0.0)), effect.none())
    }

    ClockTick -> case model.page {
      Clock -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, model.temp_conversion), effect.from(tick))
      _ -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())
    }

    UserDistance(num) -> #(Model(model.page, t.system_time(), DistConversion(num, model.dist_conversion.num_per_meter1, model.dist_conversion.num_per_meter2), model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())
    DistanceRatio1(num) -> #(Model(model.page, t.system_time(), DistConversion(model.dist_conversion.dist, num, model.dist_conversion.num_per_meter2), model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())
    DistanceRatio2(num) -> #(Model(model.page, t.system_time(), DistConversion(model.dist_conversion.dist, model.dist_conversion.num_per_meter1, num), model.weight_conversion, model.time_conversion, model.temp_conversion), effect.none())

    UserWeight(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, WeightConversion(num, model.weight_conversion.num_per_kg1, model.weight_conversion.num_per_kg2), model.time_conversion, model.temp_conversion), effect.none())
    WeightRatio1(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, WeightConversion(model.weight_conversion.weight, num, model.weight_conversion.num_per_kg2), model.time_conversion, model.temp_conversion), effect.none())
    WeightRatio2(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, WeightConversion(model.weight_conversion.weight, model.weight_conversion.num_per_kg1, num), model.time_conversion, model.temp_conversion), effect.none())

    UserTime(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, TimeConversion(num, model.time_conversion.num_in_seconds1, model.time_conversion.num_in_seconds2), model.temp_conversion), effect.none())
    TimeRatio1(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, TimeConversion(model.time_conversion.time, num, model.time_conversion.num_in_seconds2), model.temp_conversion), effect.none())
    TimeRatio2(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, TimeConversion(model.time_conversion.time, model.time_conversion.num_in_seconds1, num), model.temp_conversion), effect.none())

    UserTemp(num) -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, TempConversion(num, model.temp_conversion.steps_per_c1, model.temp_conversion.temp_at_freezing1, model.temp_conversion.steps_per_c2, model.temp_conversion.temp_at_freezing2)), effect.none())
    TempRatio1(num1, num2) -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, TempConversion(model.temp_conversion.temp, num1, num2, model.temp_conversion.steps_per_c2, model.temp_conversion.temp_at_freezing2)), effect.none())
    TempRatio2(num1, num2) -> #(Model(model.page, t.system_time(), model.dist_conversion, model.weight_conversion, model.time_conversion, TempConversion(model.temp_conversion.temp, model.temp_conversion.steps_per_c1, model.temp_conversion.temp_at_freezing1, num1, num2)), effect.none())

    _ -> #(model, effect.none())
  }
}

fn tick(dispatch){
  let s_and_n = t.to_unix_seconds_and_nanoseconds(t.system_time())
  let offset = float.truncate(926.0 *. {1.0 -. decimal_part({{int.to_float(case s_and_n{#(s, _) -> s}) *. 27.0} /. 25.0} +. {int.to_float(case s_and_n {#(_, n) -> n}) /. 925925926.0})})
  global.set_timeout(offset, fn() {dispatch(ClockTick)})
  Nil
}

fn decimal_part(num: Float) -> Float {
  num -. int.to_float(float.truncate(num))
}

fn view(model: Model) -> Element(Message) {
  h.html([], [
    h.head([], [h.title([], "Roir Resources")]),
    h.body([], [
      h.header([a.style("margin-bottom", "20px")], [h.div([a.style("margin-left", "5px")], [
        h.h1([a.styles([#("display", "inline-grid"), #("margin-right", "75px")])],
          [h.text("Roir Resources")]),
        h.button([event.on_click(UserClickedHome), a.style("margin-right", "50px")],
          [h.h2([], [h.text("Home")])]),
        h.button([event.on_click(UserClickedClock), a.style("margin-right", "50px")],
          [h.h2([], [h.text("Clock")])]),
        h.button([event.on_click(UserClickedConversion), a.style("margin-right", "50px")],
          [h.h2([], [h.text("Unit Conversion")])]),
        h.a([a.href("https://conworkshop.com/view_language.php?l=ROIR"), a.styles([#("margin-right", "50px"), #("display", "inline-grid")])],
          [h.h2([], [h.text("CWS")])]),
        h.a([a.href("https://docs.google.com/document/d/1mwD9ZAoW1PrKS8-Yidn1gpv_qTTFLY26aHr-Rd4gVtc/edit?usp=sharing"), a.style("display", "inline-grid")],
          [h.h2([], [h.text("Reference Doc")])])
      ])]),

      case model.page {
        Home -> h.div([a.style("margin-left", "5px")], [
          h.h2([], [h.text("About Roir")]),
          h.p([a.style("display", "inline-block")], [
            h.text("Roir ("),
            h.span([a.style("display", "inline-block")], [h.h4([], [h.text("rlr")])]),
            h.text(") is a Constructed Language (Conlang) created by Selkie Lunarose Yukimori. It is currently incomplete and in active development.
              For the most comprehensive breakdown of this Conlang, check the "),
            h.a([a.href("https://docs.google.com/document/d/1mwD9ZAoW1PrKS8-Yidn1gpv_qTTFLY26aHr-Rd4gVtc/edit?usp=sharing"), a.style("text-decoration", "underline")], [h.text("Roir Reference Document")]),
            h.text(", or if you feel inclined you can view the "),
            h.a([a.href("https://conworkshop.com/view_language.php?l=ROIR"), a.style("text-decoration", "underline")], [h.text("Conworkshop Page")]),
            h.text(". Both are also accessible at the top menu at any time.")
          ])
        ])

        Clock -> h.div([], [
          h.h4([a.styles([#("font-size", "5rem"), #("text-align", "center"), #("margin-top", "50px")])], [h.text(case time_in_roir(t.add(model.time, calendar.local_offset())) {
            Ok(value) -> value
            Error(_) -> "._._.._.."
          })])
        ])

        Conversion -> h.div([], [distance_conversion(model), weight_conversion(model), time_conversion(model), temp_conversion(model)])
      }
    ])
  ])
}

fn distance_conversion(model: Model) -> Element(Message) {
  h.div([a.styles([#("margin-left", "5px"), #("margin-bottom", "20px")])], [
    h.h2([], [h.text("Distance")]),
    h.div([a.style("margin-bottom", "10px")], [
      h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {DistanceRatio1(case input {
        "Zaoth" -> 29.386561536 /. 3.747405725
        "Feet" -> 12.5 /. 3.81
        "Inches" -> 50.0 /. 1.27
        "Meters" -> 1.0
        "Centimeters" -> 100.0
        "Zoith" -> 1.36048896 /. 37.47405725
        "Miles" -> 1.25 /. 2011.68
        "Kilometers" -> 0.001
        "Zaith" -> 91403.9610016 /. 1.49896229
        "Thou" -> 50000.0 /. 1.27
        "Millimeters" -> 1000.0
        _ -> 0.0
      })})], [
        h.option([], "Zaoth"),
        h.option([], "Feet"),
        h.option([a.selected(True)], "Inches"),
        h.option([], "Meters"),
        h.option([], "Centimeters"),
        h.option([], "Zoith"),
        h.option([], "Miles"),
        h.option([], "Kilometers"),
        h.option([], "Zaith"),
        h.option([], "Thou"),
        h.option([], "Millimeters")
      ]),
      h.p([a.styles([#("margin-left", "10px"), #("margin-right", "10px"), #("display", "inline-block")])], [h.text("to")]),
      h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {DistanceRatio2(case input {
        "Zaoth" -> 29.386561536 /. 3.747405725
        "Feet" -> 12.5 /. 3.81
        "Inches" -> 50.0 /. 1.27
        "Meters" -> 1.0
        "Centimeters" -> 100.0
        "Zoith" -> 1.36048896 /. 37.47405725
        "Miles" -> 1.25 /. 2011.68
        "Kilometers" -> 0.001
        "Zaith" -> 91403.9610016 /. 1.49896229
        "Thou" -> 50000.0 /. 1.27
        "Millimeters" -> 1000.0
        _ -> 0.0
      })})], [
        h.option([a.selected(True)], "Zaoth"),
        h.option([], "Feet"),
        h.option([], "Inches"),
        h.option([], "Meters"),
        h.option([], "Centimeters"),
        h.option([], "Zoith"),
        h.option([], "Miles"),
        h.option([], "Kilometers"),
        h.option([], "Zaith"),
        h.option([], "Thou"),
        h.option([], "Millimeters")
      ])
    ]),
    h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Input"), a.min("0"), event.on_change(fn(input) {case float.parse(input) {
      Ok(dist) -> UserDistance(dist)
      Error(_) -> case int.parse(input) {
        Ok(dist) -> UserDistance(int.to_float(dist))
        Error(_) -> None
      }
    }})]),
    h.p([a.styles([#("margin-left", "13px"), #("margin-right", "13px"), #("display", "inline-block")])], [h.text("=")]),
    h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Output"), a.readonly(True), a.value(float.to_string({model.dist_conversion.dist *. model.dist_conversion.num_per_meter2} /. model.dist_conversion.num_per_meter1))])
  ])
}

fn weight_conversion(model: Model) -> Element(Message) {
  h.div([a.styles([#("margin-left", "5px"), #("margin-bottom", "20px")])], [
  h.h2([], [h.text("Weight")]),
  h.div([a.style("margin-bottom", "10px")], [
  h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {WeightRatio1(case input {
    "Zaok" -> 3.172169114198268924301601144832 /. 6.578125590179196664876931640625
    "Pounds" -> 10.0 /. 4.5359237
    "Kilograms" -> 1.0
    "Zaik" -> 685.188528666826087649145847283712 /. 6.578125590179196664876931640625
    "Ounces" -> 160.0 /. 4.5359237
    "Grams" -> 1000.0
    "Zoik" -> 1.4685968121288282056951857152 /. 657.8125590179196664876931640625
    "Tons" -> 1.0 /. 907.18474
    "Metric Tons" -> 1.0 /. 1000.0
    _ -> 0.0
  })})], [
    h.option([], "Zaok"),
    h.option([a.selected(True)], "Pounds"),
    h.option([], "Kilograms"),
    h.option([], "Zaik"),
    h.option([], "Ounces"),
    h.option([], "Grams"),
    h.option([], "Zoik"),
    h.option([], "Tons"),
    h.option([], "Metric Tons")
  ]),
  h.p([a.styles([#("margin-left", "10px"), #("margin-right", "10px"), #("display", "inline-block")])], [h.text("to")]),
  h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {WeightRatio2(case input {
    "Zaok" -> 3.172169114198268924301601144832 /. 6.578125590179196664876931640625
    "Pounds" -> 10.0 /. 4.5359237
    "Kilograms" -> 1.0
    "Zaik" -> 685.188528666826087649145847283712 /. 6.578125590179196664876931640625
    "Ounces" -> 160.0 /. 4.5359237
    "Grams" -> 1000.0
    "Zoik" -> 1.4685968121288282056951857152 /. 657.8125590179196664876931640625
    "Tons" -> 1.0 /. 907.18474
    "Metric Tons" -> 1.0 /. 1000.0
    _ -> 0.0
  })})], [
    h.option([a.selected(True)], "Zaok"),
    h.option([], "Pounds"),
    h.option([], "Kilograms"),
    h.option([], "Zaik"),
    h.option([], "Ounces"),
    h.option([], "Grams"),
    h.option([], "Zoik"),
    h.option([], "Tons"),
    h.option([], "Metric Tons")
  ])
  ]),
  h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Input"), a.min("0"), event.on_change(fn(input) {case float.parse(input) {
    Ok(weight) -> UserWeight(weight)
    Error(_) -> case int.parse(input) {
      Ok(weight) -> UserWeight(int.to_float(weight))
      Error(_) -> None
    }
  }})]),
  h.p([a.styles([#("margin-left", "13px"), #("margin-right", "13px"), #("display", "inline-block")])], [h.text("=")]),
  h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Output"), a.readonly(True), a.value(float.to_string({model.weight_conversion.weight *. model.weight_conversion.num_per_kg2} /. model.weight_conversion.num_per_kg1))])
  ])
}

fn time_conversion(model: Model) -> Element(Message) {
  h.div([a.styles([#("margin-left", "5px"), #("margin-bottom", "20px")])], [
  h.h2([], [h.text("Time")]),
  h.div([a.style("margin-bottom", "10px")], [
  h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {TimeRatio1(case input {
    "Zis" -> 2.5 /. 2.7
    "Seconds" -> 1.0
    "Zus" -> 100.0 /. 3.0
    "Minutes" -> 60.0
    "Zos" -> 1200.0
    "Hours" -> 3600.0
    "Days / Zas" -> 86400.0
    _ -> 0.0
  })})], [
    h.option([], "Zis"),
    h.option([a.selected(True)], "Seconds"),
    h.option([], "Zus"),
    h.option([], "Minutes"),
    h.option([], "Zos"),
    h.option([], "Hours"),
    h.option([], "Days / Zas")
  ]),
  h.p([a.styles([#("margin-left", "10px"), #("margin-right", "10px"), #("display", "inline-block")])], [h.text("to")]),
  h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {TimeRatio2(case input {
    "Zis" -> 2.5 /. 2.7
    "Seconds" -> 1.0
    "Zus" -> 100.0 /. 3.0
    "Minutes" -> 60.0
    "Zos" -> 1200.0
    "Hours" -> 3600.0
    "Days / Zas" -> 86400.0
    _ -> 0.0
  })})], [
    h.option([a.selected(True)], "Zis"),
    h.option([], "Seconds"),
    h.option([], "Zus"),
    h.option([], "Minutes"),
    h.option([], "Zos"),
    h.option([], "Hours"),
    h.option([], "Days / Zas")
  ])
  ]),
  h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Input"), a.min("0"), event.on_change(fn(input) {case float.parse(input) {
    Ok(time) -> UserTime(time)
    Error(_) -> case int.parse(input) {
      Ok(time) -> UserTime(int.to_float(time))
      Error(_) -> None
    }
  }})]),
  h.p([a.styles([#("margin-left", "13px"), #("margin-right", "13px"), #("display", "inline-block")])], [h.text("=")]),
  h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Output"), a.readonly(True), a.value(float.to_string({model.time_conversion.time *. model.time_conversion.num_in_seconds1} /. model.time_conversion.num_in_seconds2))])
  ])
}

fn temp_conversion(model: Model) -> Element(Message) {
  h.div([a.styles([#("margin-left", "5px"), #("margin-bottom", "20px")])], [
  h.h2([], [h.text("Temperature")]),
  h.div([a.style("margin-bottom", "10px")], [
  h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {case input {
    "Toiz" -> TempRatio1(2.16, 0.0)
    "Fahrenheit" -> TempRatio1(1.8, 32.0)
    "Celsius" -> TempRatio1(1.0, 0.0)
    "Kelvin" -> TempRatio1(1.0, 273.15)
    _ -> TempRatio1(0.0, 0.0)
  }})], [
    h.option([], "Toiz"),
    h.option([a.selected(True)], "Fahrenheit"),
    h.option([], "Celsius"),
    h.option([], "Kelvin")
  ]),
  h.p([a.styles([#("margin-left", "10px"), #("margin-right", "10px"), #("display", "inline-block")])], [h.text("to")]),
  h.select([a.styles([#("font-size", "115%"), #("width", "230px")]), event.on_change(fn(input) {case input {
    "Toiz" -> TempRatio2(2.16, 0.0)
    "Fahrenheit" -> TempRatio2(1.8, 32.0)
    "Celsius" -> TempRatio2(1.0, 0.0)
    "Kelvin" -> TempRatio2(1.0, 273.15)
    _ -> TempRatio2(0.0, 0.0)
  }})], [
    h.option([a.selected(True)], "Toiz"),
    h.option([], "Fahrenheit"),
    h.option([], "Celsius"),
    h.option([], "Kelvin")
  ])
  ]),
  h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Input"), event.on_change(fn(input) {case float.parse(input) {
    Ok(temp) -> UserTemp(temp)
    Error(_) -> case int.parse(input) {
      Ok(temp) -> UserTemp(int.to_float(temp))
      Error(_) -> None
    }
  }})]),
  h.p([a.styles([#("margin-left", "13px"), #("margin-right", "13px"), #("display", "inline-block")])], [h.text("=")]),
  h.input([a.style("font-size", "115%"), a.type_("text"), a.placeholder("Output"), a.readonly(True), a.value(float.to_string({{{model.temp_conversion.temp -. model.temp_conversion.temp_at_freezing1} *. model.temp_conversion.steps_per_c2} /. model.temp_conversion.steps_per_c1} +. model.temp_conversion.temp_at_freezing2))])
  ])
}

pub fn time_in_roir(current_time: t.Timestamp) -> Result(String, String) {
  let time = time_to_roir(current_time)

  use phase <- result.try(case time {
    #(0, _, _, _, _) -> Ok("a_")
    #(1, _, _, _, _) -> Ok("o_")
    #(2, _, _, _, _) -> Ok("u_")
    #(3, _, _, _, _) -> Ok("i_")
    #(value, _, _, _, _) -> Error("Unexpected value: #(" <> int.to_string(value) <> ", _, _, _, _")
  })

  use chunk <- result.try(case time {
    #(_, 0, _, _, _) -> Ok("v_")
    #(_, 1, _, _, _) -> Ok("q_")
    #(_, 2, _, _, _) -> Ok("l_")
    #(_, value, _, _, _) -> Error("Unexpected value: #(_, " <> int.to_string(value) <> ", _, _, _")
  })

  let hour = int.to_string(case time {#(_, _, h, _, _) -> h}) <> "_"
  let minute = to_2digit_base6(case time {#(_, _, _, m, _) -> m}) <> "_"
  let second = to_2digit_base6(case time {#(_, _, _, _, s) -> s})

  Ok(phase <> chunk <> hour <> minute <> second)
}

fn to_2digit_base6(num: Int) -> String {
  int.to_string({num / 6} % 6) <> int.to_string(num % 6)
}

pub fn time_to_roir(current_time: t.Timestamp) -> #(Int, Int, Int, Int, Int) {
  let #(_, time) = t.to_calendar(t.subtract(current_time, duration.hours(4)), calendar.utc_offset)
  #(
    time.hours / 6,
    {time.hours / 2} % 3,
    {{{time.hours * 60} + time.minutes} / 20} % 6,
    {float.truncate({{int.to_float({{{time.hours * 60} + time.minutes} * 60} + time.seconds) *. 27.0} /. 25.0} +. {int.to_float(time.nanoseconds) /. 925925926.0}) / 36} % 36,
    float.truncate({{int.to_float({{{time.hours * 60} + time.minutes} * 60} + time.seconds) *. 27.0} /. 25.0} +. {int.to_float(time.nanoseconds) /. 925925926.0}) % 36
  )
}