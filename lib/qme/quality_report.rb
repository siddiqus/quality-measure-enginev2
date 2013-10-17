module QME
  
  # A class that allows you to create and obtain the results of running a
  # quality measure against a set of patient records.
  class QualityReport
    
    include DatabaseAccess
    extend DatabaseAccess
    determine_connection_information

    POPULATION = 'IPP'
    DENOMINATOR = 'DENOM'
    NUMERATOR = 'NUMER'
    EXCLUSIONS = 'DENEX'
    EXCEPTIONS = 'DENEXCEP'
    MSRPOPL = 'MSRPOPL'
    OBSERVATION = 'OBSERV'
    ANTINUMERATOR = 'antinumerator'
    CONSIDERED = 'considered'
  
    RACE = 'RACE'
    ETHNICITY = 'ETHNICITY'
    SEX ='SEX'
    POSTAL_CODE = 'POSTAL_CODE'
    PAYER   = 'PAYER'

    # Gets rid of all calculated QualityReports by dropping the patient_cache
    # and query_cache collections
    def self.destroy_all
      determine_connection_information
      get_db()["query_cache"].drop
      get_db()["patient_cache"].drop
    end
    
    # Removes the cached results for the patient with the supplied id and
    # recalculates as necessary
    def self.update_patient_results(id)
      determine_connection_information()
      
      # TODO: need to wait for any outstanding calculations to complete and then prevent
      # any new ones from starting until we are done.

      # drop any cached measure result calculations for the modified patient
      get_db()["patient_cache"].find('value.medical_record_id' => id).remove_all()
      
      # get a list of cached measure results for a single patient
      sample_patient = get_db()['patient_cache'].find().first()
      if sample_patient
        cached_results = get_db()['patient_cache'].find({'value.patient_id' => sample_patient['value']['patient_id']})
        
        # for each cached result (a combination of measure_id, sub_id, effective_date and test_id)
        cached_results.each do |measure|
          # recalculate patient_cache value for modified patient
          value = measure['value']
          map = QME::MapReduce::Executor.new(value['measure_id'], value['sub_id'],
            'effective_date' => value['effective_date'], 'test_id' => value['test_id'])
          map.map_record_into_measure_groups(id)
        end
      end
      
      # remove the query totals so they will be recalculated using the new results for
      # the modified patient
      get_db()["query_cache"].drop()
    end

    # Creates a new QualityReport
    # @param [String] measure_id value of the measure's id field
    # @param [String] sub_id value of the measure's sub_id field, may be nil 
    #                 for measures with only a single numerator and denominator
    # @param [Hash] parameter_values slots in the measure definition that need to
    #               be filled in and an optional test_id to identify a sub-population.
    def initialize(measure_id, sub_id, parameter_values)
      @measure_id = measure_id
      @sub_id = sub_id
      @parameter_values = parameter_values
      determine_connection_information
    end
    
    # Determines whether the quality report has been calculated for the given
    # measure and parameters
    # @return [true|false]
    def calculated?
      ! result().nil?
    end

    # Determines whether the patient mapping for the quality report has been
    # completed
    def patients_cached?
      ! patient_result().nil?
    end
    
    # Kicks off a background job to calculate the measure
    # @return a unique id for the measure calculation job
    def calculate(asynchronous=true)
      
      options = {'measure_id' => @measure_id, 'sub_id' => @sub_id}
      
      options.merge! @parameter_values
      options['filters'] = QME::QualityReport.normalize_filters(@parameter_values['filters'])
      
      if (asynchronous)
        job = Delayed::Job.enqueue(QME::MapReduce::MeasureCalculationJob.new(options))
        job._id
      else
        mcj = QME::MapReduce::MeasureCalculationJob.new(options)
        mcj.perform
      end
    end
    
    # Returns the status of a measure calculation job
    # @param job_id the id of the job to check on
    # @return [Symbol] Will return the status: :complete, :queued, :running, :failed
    def status(job_id)
      job = Delayed::Job.where(_id: job_id).first
      if job.nil?
        # If we can't find the job, we assume that it is complete
        :complete
      else
        if job.locked_at.nil?
          :queued
        else
          if job.failed?
            :failed
          else
            :running
          end            
        end
      end
    end
    
    # Gets the result of running a quality measure
    # @return [Hash] measure groups (like numerator) as keys, counts as values or nil if
    #                the measure has not yet been calculated
    def result
      cache = get_db()["query_cache"]
      query = {:measure_id => @measure_id, :sub_id => @sub_id, 
               :effective_date => @parameter_values['effective_date'],
               :test_id => @parameter_values['test_id']}
      if @parameter_values['filters']
        query.merge!({filters: QME::QualityReport.normalize_filters(@parameter_values['filters'])})
      else
        query.merge!({filters: nil})
      end
        
      cache.find(query).first()
    end
    
    # make sure all filter id arrays are sorted
    def self.normalize_filters(filters)
      filters.each {|key, value| value.sort_by! {|v| (v.is_a? Hash) ? "#{v}" : v} if value.is_a? Array} unless filters.nil?
    end
    
    def patient_result(patient_id = nil)
      cache = get_db()["patient_cache"]
      query = {'value.measure_id' => @measure_id, 'value.sub_id' => @sub_id, 
               'value.effective_date' => @parameter_values['effective_date'],
               'value.test_id' => @parameter_values['test_id']}
      if patient_id
        query['value.medical_record_id'] = patient_id
      end
      cache.find(query).first()
    end
    
  end
end
