require 'yaml'
MESSAGES = YAML.load_file('rock_paper_messages.yml')

def print_title(title:, margin: 10)
  length = title.size
  frame = format("%*s\n\n", margin + length, "_" * length)
  content = format("%*s\n", margin + length, title)
  print frame
  print content
  print frame
end

def print_list(title: "List title", list: ["list el"], margin: 10)
  title = format("%*s%-1s\n\n", margin, '', title)
  print title
  list.each do |list_el|
    print format("%*s%s%-1s\n", margin, '', '- ', list_el)
  end
end

def print_frame(margin: 10, length: 56)
  frame = format("%*s\n\n", margin + length, "_" * length)
  print frame
end

def print_col_pipe(col1: "content1", col2: "content2", margin: 10, col_len: 19)
  padding = col_len - col1.size
  column1 = format("%*s%-1s%*s", margin, '', col1, padding, '|')
  column2 = format(" %-1s\n", col2)
  print column1
  print column2
end

def print_intro
  print_title(title: MESSAGES['welcome'])
  print_list(title: MESSAGES['rules_title'], list: MESSAGES['rules'])
  print_frame
  col1 = MESSAGES['choices_table_h'][0]
  col2 = MESSAGES['choices_table_h'][1]
  print_col_pipe(col1: col1, col2: col2)
  print_frame
  MESSAGES['choices_table_r'].each do |first_col, second_col|
    print_col_pipe(col1: first_col, col2: second_col)
  end
  print_frame
end
