// including plugins
var gulp = require('gulp');
var gutil = require('gulp-util');
var coffee = require("gulp-coffee");
var del = require('del');

var bases = {
  src: './src/**/*.coffee',
  dist: './lib/'
};
var coffeeOptions = {
  bare: true
};

var compileCoffee = function() {
  gulp.src(bases.src)
    .pipe(coffee(coffeeOptions).on('error', gutil.log))
    .pipe(gulp.dest(bases.dist));
};

gulp.task('clean', function(cb) {
  del([bases.dist], cb);
});

gulp.task('compile-coffee', compileCoffee);

gulp.task('build', ['clean'], compileCoffee);

gulp.task('watch-coffee', function () {
  gulp.watch(bases.src, ['compile-coffee']);
});

gulp.task('default', function() {
  gulp.start('compile-coffee');
});