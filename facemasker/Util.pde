
String[] listFileNames(String dir, boolean filter, final String extension, final String excludePrefix) {
  File file = new File(dir);
  if (file.isDirectory()) {
    if (!filter)
      return file.list();
    String names[] = file.list(new FilenameFilter() {
      public boolean accept(File dir, String name) {
        boolean ok = false;
        if (name.endsWith(extension))
          ok = true;

        if (!ok)
          return false;
        if (excludePrefix != null)
          return !name.startsWith(excludePrefix);
        else
          return true;
      }
    }
    );
    return names;
  } 
  else {
    // If it's not a directory
    return null;
  }
}

