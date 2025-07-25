// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "40",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "STIX Two Text", size: 16pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 50pt,
      image(univ_logo, width: univ_logo_scale),
      text(title_font_size, title + "\n\n") + 
      text(authors_font_size, emph(authors) + 
          "   (" + departments + ") "),
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [HDI vs GDP Per Capita Visualization], 
  // TODO: use Quarto's normalized metadata.
   authors: [Tan Zi Xu ,Teo Royston, Sim Yue Chong Samuel, Ng Kay Cheng, Ramasubramanian Srinithi], 
  
   size: "36x24", 

  // Institution logo.
   univ_logo: "./images/sit.png", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [AAI1001 AY24/25 Tri 2 Team Project], 

  // Any URL, like a link to the conference website.
  

  // Emails of the authors.
   footer_email_ids: [Team 14], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)


= Introduction
<introduction>
Global development remains an ongoing challenge, as disparities in income and well-being continue to define the divide between developed and developing countries. While GDP per capita remains a common prosperity metric, it falls short in capturing crucial dimensions of quality of life like education and healthcare. The Human Development Index (HDI), a composite measure of income, life expectancy, and schooling, offers a more holistic benchmark, yet even it may not fully reveal the complex interplay of factors driving inequality across nations

Our project builds upon the Our World in Data visualization of HDI vs.~GDP per capita (2023), which effectively uses population-sized bubbles and region-based coloring to enhance its analytical depth. Through targeted refinements and potential integration of additional socio-economic dimensions, we aim to uncover more nuanced patterns in global development, highlight persistent gaps in human well-being, and provide a clearer visual narrative to inform crucial discussions on global inequality and progress.

= Original Visualization
<original-visualization>
#figure([
#box(image("images/visualisation.png"))
], caption: figure.caption(
position: bottom, 
[
HDI vs GDP per Capita
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= Critical Assessment of Original Visualization
<critical-assessment-of-original-visualization>
== #emph[Strengths]
<strengths>

#horizontalrule

+ #strong[Clear Correlation Between GDP and HDI] : The scatter plot successfully reveals a strong positive relationship between a country’s GDP per capita and its Human Development Index (HDI). This validates the use of GDP as a proxy for national well-being in initial explorations.

+ #strong[Interactive and Engaging with Tooltips] : Users can hover over each bubble to reveal country-specific information. This interactivity enhances user engagement and facilitates exploration of the data without overwhelming the visual with text.

+ #strong[Use of Globally Recognized Indicators] : Both GDP per capita and HDI are well-established, widely understood indicators. This makes the visualization accessible to both general audiences and experts.

+ #strong[Temporal Slider Enables Yearly Comparisons] : The time slider allows users to explore how the relationship evolves over time (1990–2023), supporting temporal analysis and helping spot historical trends or anomalies.

+ #strong[Colour-Coded by Region for Broad Comparison] : Countries are grouped by continent using distinct colours, which aids users in performing regional comparisons and spotting geographical clusters or outliers.

+ #strong[Bubble Size Reflects Population] : The use of proportional bubble sizing adds an extra layer of information, emphasizing the relative population size of each country and showing how populous nations (e.g., India, China) contribute to global trends.

+ #strong[Log Scale Compresses Wide GDP Range] : A logarithmic scale on the x-axis handles the vast differences in GDP per capita values effectively, allowing low-income and high-income countries to be shown on the same scale without excessive crowding.

== #emph[Weaknesses]
<weaknesses>

#horizontalrule

+ #strong[Axis Labels lack clarity, not enough intuitive context];: The x- and y-axis labels lack intuitive explanations. There is no quick contextual guide for non-technical viewers to interpret what a high or low HDI or GDP implies.

+ #strong[Overlapping points in dense regions];: In low-GDP regions, many data points overlap, making it difficult to distinguish individual countries and reducing readability.

+ #strong[No trendlines/regression analysis];: Although a general upward pattern is visible, the lack of a fitted line limits the user’s ability to assess the strength and consistency of the correlation quantitatively.

+ #strong[No filters by region, income group or custom years];: Users cannot filter the dataset by custom groupings such as "Low Income Countries" or "East Asia". This limits focused exploration and comparative analysis.

+ #strong[Low contrast thus not colour-blind friendly];: Some region colours are low in contrast and may not be distinguishable by colour-blind users. The visual fails to meet universal design or accessibility guidelines.

+ #strong[Bubbles sizing overshadow smaller countries];: Large countries like India and China dominate the chart visually due to their population size, which can unintentionally de-emphasize trends in smaller nations.

+ #strong[Population sizing methodology unclear];: It is unclear whether population sizes are static or dynamic over time as the bubble is not showing distinct changes.

= Suggested Improvements
<suggested-improvements>
+ #strong[Define a Clear Narrative];: Establish a clear distinction between developed and developing countries using HDI and GDP thresholds to guide interpretation and analysis.

+ #strong[Contextual Bands Along X & Y Axes];: Add labeled bands along both HDI and GDP axes to visually segment income and development categories, improving clarity and comparative insight.

+ #strong[Boundary Threshold Lines for Developed vs Developing Classification];: Introduce boundary lines to clearly demarcate developed from developing countries within the scatterplot.

+ #strong[Filters by Development Status, Region, and Year];: Implement filters that allow users to isolate countries by development status, geographic region, or custom year ranges for more focused exploration.

+ #strong[Dynamic Yearly Summary Panel];: Provide a yearly statistics panel displaying average, median, min, and max values of HDI and GDP for both developed and developing groups.

+ #strong[Improve Visual Accessibility and Clarity];: Reduce bubble overlap in dense areas through jittering and zoom features, and apply colorblind-safe palettes to ensure accessibility for all users.

+ #strong[Animated Time lapse with Annotations];: Integrate an animated timeline to show changes from 1990–2023, with pauses and annotations at key milestones to emphasize global development trends.

= Implementation
<implementation>
== Data Source
<data-source>

#horizontalrule

UNDP – Human Development Report (2025), Eurostat, OECD, and World Bank (2025) ,HYDE (2023) – History Database of the Global Environment, Gapminder – Population v7 (2022), UN – World Population Prospects (2024), Gapminder – Systema Globalis (2022), Our World in Data – with major processing by Our World in Data

== Software
<software>

#horizontalrule

We used R and a range of packages to clean, analyze, and visualize the data:

- readr – for importing cleaned CSV files
- dplyr – for filtering, grouping, and summarising data
- ggplot2 – for static visualizations such as boxplots and scatter plots
- plotly – for interactive and animated development plots
- scales – to format axis labels and numerical values clearly
- tibble – to define development bands used in visual overlays
- stats – to compute correlations, trends, and regression models

== Workflow
<workflow>
#block[
#set enum(numbering: "1)", start: 1)
+ Exploratory Data Analysis:

+ Feature Engineering:

+ Data Visualization:
]

= Improved Visualization
<improved-visualization>
= Further Improvements
<further-improvements>
= References
<references>
= Further Reading
<further-reading>



