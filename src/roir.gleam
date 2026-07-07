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
  time: t.Timestamp
)}

type Page {
  Home
  Clock
  Conversion
}

fn init(_flags) -> #(Model, effect.Effect(Message)) {
  #(Model(Home, t.system_time()), effect.none())
}

type Message {
  UserClickedHome
  UserClickedClock
  UserClickedConversion
  ClockTick
}

fn update(model : Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    UserClickedHome -> #(Model(Home, t.system_time()), effect.none())
    UserClickedClock -> case model.page {
      Clock -> #(Model(Clock, t.system_time()), effect.none())
      _ -> #(Model(Clock, t.system_time()), effect.from(tick))
    }
    UserClickedConversion -> #(Model(Conversion, t.system_time()), effect.none())
    ClockTick -> case model.page {
      Clock -> #(Model(model.page, t.system_time()), effect.from(tick))
      _ -> #(Model(model.page, t.system_time()), effect.none())
    }
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
          })])]
        )
        Conversion -> h.div([], [
          h.text("This section is unfinished.")
        ])
      }
    ])
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